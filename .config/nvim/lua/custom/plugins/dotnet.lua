-- .NET / C# development: the Roslyn language server via roslyn.nvim and netcoredbg
-- for debugging, with the same IntelliJ-style action menu and keys as java.lua.
-- Inside a .NET project (a .sln/.csproj above the current file or cwd) the keys
-- below do the .NET thing; everywhere else they keep doing the Java thing.
--
--   <leader>jj   .NET menu: run / debug / restart / tests / dotnet CLI / EF Core / ...
--   <leader>jp   Launch profile picker (Properties/launchSettings.json), also :DotnetProfile
--   <leader>jv   Installed .NET SDKs and the one this project uses, also :DotnetSdk
--   <S-F10>      Re-run (restart) the last run / debug    (IntelliJ: Shift+F10)
--   <S-F9>       Debug                                     (IntelliJ: Shift+F9)
--   <C-F2>       Stop app, or else the running dotnet command (IntelliJ: Ctrl+F2)
--   <leader>dc   Toggle the app console
--   <A-o>        Remove unnecessary usings
--
-- Run uses `dotnet run` in a terminal split, Debug builds first and starts the
-- app under netcoredbg; both get the launch profile's environment and URLs.
-- Debugger keys (F7/F8/F9...) live in lua/kickstart/plugins/debug.lua.

vim.pack.add { 'https://github.com/seblyng/roslyn.nvim' }

require('roslyn').setup {}
vim.lsp.config('roslyn', {
  settings = {
    ['csharp|inlay_hints'] = {
      csharp_enable_inlay_hints_for_implicit_object_creation = true,
      csharp_enable_inlay_hints_for_implicit_variable_types = true,
      dotnet_enable_inlay_hints_for_parameters = true,
    },
    ['csharp|completion'] = {
      dotnet_show_completion_items_from_unimported_namespaces = true,
    },
    ['csharp|background_analysis'] = {
      dotnet_compiler_diagnostics_scope = 'fullSolution',
    },
  },
})

local mason_bin = vim.fn.stdpath 'data' .. '/mason/bin'
local dotnet_tools = vim.fs.normalize '~/.dotnet/tools'

local function notify(msg, level) vim.notify(msg, level or vim.log.levels.INFO, { title = '.NET' }) end

local function read_file(path)
  local f = io.open(path, 'r')
  if not f then return nil end
  local content = f:read '*a'
  f:close()
  return content
end

-- ============================================================
-- Project root & per-project state (launch profile, environment, run arguments)
-- ============================================================

local function is_sln(name) return name:match '%.slnx?$' ~= nil end
local function is_csproj(name) return name:match '%.csproj$' ~= nil end

--- The current file, or the cwd for buffers that are not files (neo-tree, terminals, ...)
local function source_path(bufnr)
  local name = vim.api.nvim_buf_get_name(bufnr or 0)
  if name ~= '' and vim.uv.fs_stat(name) then return name end
  return vim.fn.getcwd()
end

--- The folder of the solution, otherwise of the nearest project file
local function project_root(bufnr)
  local path = source_path(bufnr)
  return vim.fs.root(path, is_sln) or vim.fs.root(path, is_csproj)
end

--- True when the keys should do .NET things: a .NET project is closer than a Java one
local function in_dotnet_project()
  local root = project_root()
  if not root then return false end
  local java = vim.fs.root(source_path(), { 'pom.xml', 'build.gradle', 'build.gradle.kts', 'settings.gradle', 'settings.gradle.kts' })
  return not java or #root >= #java
end

local state_file = vim.fn.stdpath 'data' .. '/dotnet-projects.json'

local function load_all_state()
  local ok, data = pcall(vim.json.decode, read_file(state_file) or '{}', { luanil = { object = true } })
  return ok and type(data) == 'table' and data or {}
end

local function project_state(root) return load_all_state()[root or project_root()] or {} end

local function save_project_state(root, changes)
  local all = load_all_state()
  all[root] = vim.tbl_extend('force', all[root] or {}, changes)
  local f = io.open(state_file, 'w')
  if f then
    f:write(vim.json.encode(all))
    f:close()
  end
end

-- ============================================================
-- Projects in the solution (.csproj)
-- ============================================================

local skip_dirs = { bin = true, obj = true, ['.git'] = true, ['.vs'] = true, ['.idea'] = true, node_modules = true }

local function csproj_files(root)
  local found = {}
  for name, type in vim.fs.dir(root, { depth = 5, skip = function(dir) return not skip_dirs[vim.fs.basename(dir)] end }) do
    if type == 'file' and is_csproj(name) then table.insert(found, root .. '/' .. name) end
  end
  table.sort(found)
  return found
end

local function project_info(csproj)
  local xml = read_file(csproj) or ''
  local output = xml:match '<OutputType>%s*(%a+)%s*</OutputType>'
  local test = xml:find('Microsoft.NET.Test.Sdk', 1, true) ~= nil or xml:match '<IsTestProject>%s*true' ~= nil
  return {
    path = csproj,
    dir = vim.fs.dirname(csproj),
    name = vim.fn.fnamemodify(csproj, ':t:r'),
    test = test,
    runnable = not test
      and (xml:find('Microsoft.NET.Sdk.Web', 1, true) ~= nil or xml:find('Microsoft.NET.Sdk.Worker', 1, true) ~= nil or output == 'Exe' or output == 'WinExe'),
    ef = xml:find('Microsoft.EntityFrameworkCore.Design', 1, true) ~= nil or xml:find('Microsoft.EntityFrameworkCore.Tools', 1, true) ~= nil,
  }
end

local function projects(root) return vim.tbl_map(project_info, csproj_files(root)) end

--- The project the current file belongs to
local function current_project()
  local dir = vim.fs.root(source_path(), is_csproj)
  if not dir then return nil end
  for _, p in ipairs(projects(dir)) do
    if p.dir == dir then return p end
  end
end

local function select_startup(root, runnable, callback)
  vim.ui.select(runnable, {
    prompt = 'Startup project · ' .. vim.fn.fnamemodify(root, ':t'),
    format_item = function(p) return (p.path == project_state(root).startup and '● ' or '  ') .. p.name end,
  }, function(choice)
    if not choice then return end
    save_project_state(root, { startup = choice.path })
    if callback then callback(choice) end
  end)
end

--- IntelliJ "run configuration": the runnable (Web/Exe) project that Run/Debug start.
--- One project: that one. Several: the saved choice, the current file's project, or ask.
local function startup_project(root, callback)
  local runnable = vim.tbl_filter(function(p) return p.runnable end, projects(root))
  if #runnable == 0 then return notify('No runnable project (Web/Worker/Exe) under ' .. root, vim.log.levels.WARN) end
  if #runnable == 1 then return callback(runnable[1]) end
  local saved = project_state(root).startup
  local current = vim.fs.root(source_path(), is_csproj)
  for _, p in ipairs(runnable) do
    if p.path == saved then return callback(p) end
  end
  for _, p in ipairs(runnable) do
    if p.dir == current then return callback(p) end
  end
  select_startup(root, runnable, callback)
end

-- ============================================================
-- Launch profiles (Properties/launchSettings.json) & environment
-- ============================================================

--- The project's "Project" launch profiles, in file order (the first is dotnet run's default)
local function launch_profiles(project)
  local content = read_file(project.dir .. '/Properties/launchSettings.json')
  if not content then return {} end
  content = content:gsub('^\239\187\191', '') -- UTF-8 BOM
  local ok, data = pcall(vim.json.decode, content, { luanil = { object = true, array = true } })
  if not ok or type(data) ~= 'table' or type(data.profiles) ~= 'table' then return {} end
  local found = {}
  for name, p in pairs(data.profiles) do
    if p.commandName == 'Project' then
      p.name = name
      p.order = content:find('"' .. vim.pesc(name) .. '"%s*:') or math.huge
      table.insert(found, p)
    end
  end
  table.sort(found, function(a, b) return a.order < b.order end)
  return found
end

--- The selected launch profile; nil when "none" was picked or the project has none
local function active_profile(root, project)
  local profiles = launch_profiles(project)
  local name = project_state(root).profile
  if name == '' then return nil end
  for _, p in ipairs(profiles) do
    if p.name == name then return p end
  end
  return profiles[1]
end

--- Environment the app runs with: the launch profile's variables and URLs, then the
--- environment override (ASPNETCORE_ENVIRONMENT) picked in the menu.
local function app_env(root, project)
  local env = {}
  local profile = active_profile(root, project)
  if profile then
    for k, v in pairs(profile.environmentVariables or {}) do
      env[k] = tostring(v)
    end
    if profile.applicationUrl and not env.ASPNETCORE_URLS then env.ASPNETCORE_URLS = profile.applicationUrl end
  end
  local override = project_state(root).environment
  if override and override ~= '' then
    env.ASPNETCORE_ENVIRONMENT = override
    env.DOTNET_ENVIRONMENT = override
  end
  return env, profile
end

--- Program arguments: the profile's commandLineArgs, then the ones set in the menu
local function app_args(root, profile)
  return vim.trim(((profile and profile.commandLineArgs) or '') .. ' ' .. (project_state(root).args or ''))
end

--- Environment for terminals: app environment plus dotnet global tools (dotnet-ef) on PATH
local function term_env(env)
  return vim.tbl_extend('force', env or {}, { PATH = dotnet_tools .. ':' .. vim.env.PATH })
end

local function select_profile()
  local root = project_root()
  if not root then return notify('Not in a .NET project', vim.log.levels.WARN) end
  startup_project(root, function(project)
    local current = active_profile(root, project)
    local items = { { name = '', label = 'none (no launch profile)' } }
    for _, p in ipairs(launch_profiles(project)) do
      local env = (p.environmentVariables or {}).ASPNETCORE_ENVIRONMENT
      table.insert(items, { name = p.name, label = p.name .. '  ' .. (p.applicationUrl or '') .. (env and ('  [' .. env .. ']') or '') })
    end
    vim.ui.select(items, {
      prompt = 'Launch profile · ' .. project.name,
      format_item = function(i) return ((current and current.name or '') == i.name and '● ' or '  ') .. i.label end,
    }, function(choice)
      if not choice then return end
      save_project_state(root, { profile = choice.name })
      notify('Launch profile: ' .. (choice.name ~= '' and choice.name or 'none') .. '\nUsed by run/debug. Restart the app (Shift+F10) to apply it.')
    end)
  end)
end

local function select_environment()
  local root = project_root()
  local current = project_state(root).environment or ''
  local items = { '', 'Development', 'Staging', 'Production', 'Custom…' }
  vim.ui.select(items, {
    prompt = 'ASPNETCORE_ENVIRONMENT',
    format_item = function(i)
      if i == 'Custom…' then return '  ' .. i end
      return (i == current and '● ' or '  ') .. (i == '' and 'from launch profile (default)' or i)
    end,
  }, function(choice)
    if not choice then return end
    local function set(value)
      save_project_state(root, { environment = value })
      notify('Environment: ' .. (value ~= '' and value or 'from launch profile') .. '\nRestart the app (Shift+F10) to apply it.')
    end
    if choice ~= 'Custom…' then return set(choice) end
    vim.ui.input({ prompt = 'ASPNETCORE_ENVIRONMENT: ', default = current }, function(input)
      if input then set(vim.trim(input)) end
    end)
  end)
end

local function edit_run_args()
  local root = project_root()
  vim.ui.input({ prompt = 'Program arguments: ', default = project_state(root).args or '' }, function(args)
    if args == nil then return end
    save_project_state(root, { args = args })
    notify 'Run arguments saved for this project'
  end)
end

-- ============================================================
-- Terminals: the running app (dotnet run / watch) and dotnet CLI commands
-- ============================================================

local app_term, tool_term

local function term_running(term)
  local job = term and term.job_id
  return job ~= nil and vim.fn.jobwait({ job }, 0)[1] == -1
end

--- Stop a terminal's command like Ctrl+C (lets ASP.NET shut down cleanly), kill it
--- if it ignores that, then call `after`.
local function stop_term(term, after)
  if not term_running(term) then
    if after then after() end
    return
  end
  local job = term.job_id
  vim.fn.chansend(job, '\3')
  local waited, timer = 0, vim.uv.new_timer()
  timer:start(100, 100, vim.schedule_wrap(function()
    waited = waited + 100
    local alive = vim.fn.jobwait({ job }, 0)[1] == -1
    if alive and waited < 5000 then return end
    timer:stop()
    timer:close()
    if alive then vim.fn.jobstop(job) end
    if after then after() end
  end))
end

local function new_term(id, opts)
  local Terminal = require('toggleterm.terminal').Terminal
  local term = Terminal:new(vim.tbl_extend('force', {
    id = id, -- fixed ids so they never take over the Ctrl+t / Alt+t terminals or Java's (99)
    direction = 'horizontal',
    close_on_exit = false,
    on_open = function() vim.cmd 'stopinsert' end,
  }, opts))
  term:open(15)
  vim.cmd 'wincmd p' -- keep editing while it runs
  return term
end

--- Run a dotnet CLI command in the shared command terminal
local function run_tool(root, cmd, opts)
  opts = opts or {}
  if opts.remember ~= false then save_project_state(root, { last_tool = cmd }) end
  if tool_term then tool_term:shutdown() end
  tool_term = new_term(97, {
    cmd = cmd,
    dir = opts.dir or root,
    env = term_env(opts.env),
    display_name = opts.name or cmd,
    on_stdout = opts.on_stdout,
  })
end

-- ============================================================
-- Debug console (netcoredbg can't run the app in a terminal, so its output
-- events are written into a terminal buffer: colors from the logger still work)
-- ============================================================

local console = { buf = nil, chan = nil, win = nil }
local last_console -- 'run' or 'debug': what <leader>dc shows

local function console_open() return console.win ~= nil and vim.api.nvim_win_is_valid(console.win) end

local function show_debug_console()
  if not console.buf or not vim.api.nvim_buf_is_valid(console.buf) then return notify 'No debug output yet — debug something first' end
  if console_open() then
    vim.api.nvim_win_set_buf(console.win, console.buf)
  else
    local prev = vim.api.nvim_get_current_win()
    vim.cmd 'botright 12split'
    console.win = vim.api.nvim_get_current_win()
    vim.api.nvim_win_set_buf(console.win, console.buf)
    vim.wo[console.win].number = false
    vim.wo[console.win].relativenumber = false
    vim.wo[console.win].signcolumn = 'no'
    vim.wo[console.win].winfixheight = true
    vim.api.nvim_set_current_win(prev)
  end
  vim.api.nvim_win_call(console.win, function() vim.cmd 'normal! G' end)
end

local function new_debug_console(name)
  local old = console.buf
  console.buf = vim.api.nvim_create_buf(false, true)
  console.chan = vim.api.nvim_open_term(console.buf, {})
  pcall(vim.api.nvim_buf_set_name, console.buf, 'dotnet://' .. name)
  if console_open() then vim.api.nvim_win_set_buf(console.win, console.buf) end
  if old and vim.api.nvim_buf_is_valid(old) then pcall(vim.api.nvim_buf_delete, old, { force = true }) end
  last_console = 'debug'
end

local function toggle_console()
  if last_console == 'run' and app_term then return app_term:toggle() end
  if console_open() then return vim.api.nvim_win_close(console.win, true) end
  show_debug_console()
end

-- ============================================================
-- Debugger (netcoredbg)
-- ============================================================

local dap = require 'dap'

-- resolved per session, so it also works right after Mason installed netcoredbg
dap.adapters.coreclr = function(callback)
  callback {
    type = 'executable',
    command = vim.fn.executable(mason_bin .. '/netcoredbg') == 1 and (mason_bin .. '/netcoredbg') or 'netcoredbg',
    args = { '--interpreter=vscode' },
  }
end

dap.listeners.after.event_output['dotnet-console'] = function(session, body)
  if session.config.type ~= 'coreclr' or body.category == 'telemetry' or not console.chan then return end
  vim.api.nvim_chan_send(console.chan, (body.output:gsub('\r?\n', '\r\n')))
end

dap.listeners.after.launch['dotnet-console'] = function(session, err)
  if not err and session.config.type == 'coreclr' then show_debug_console() end
end

-- ============================================================
-- Build (before debugging)
-- ============================================================

--- C# compiler errors from msbuild output (msbuild prints each one twice)
local function build_errors(output)
  local items, seen = {}, {}
  for line in output:gmatch '[^\r\n]+' do
    local file, lnum, col, kind, code, msg = line:match '^%s*(.-)%((%d+),(%d+)%):%s*(%a+)%s+(%w+):%s*(.-)%s*%[[^%]]*%]%s*$'
    local key = file and (file .. lnum .. col .. code)
    if kind == 'error' and not seen[key] then
      seen[key] = true
      table.insert(items, { filename = file, lnum = tonumber(lnum), col = tonumber(col), type = 'E', text = code .. ': ' .. msg })
    end
  end
  return items
end

local target_paths = {} -- csproj -> built dll

--- IntelliJ "Build before run": save everything, `dotnet build` the project and
--- call on_built(dll). Compile errors go to the quickfix list.
local function build(project, on_built)
  vim.cmd 'silent! wall'
  vim.api.nvim_echo({ { 'Building ' .. project.name .. '…', 'Comment' } }, false, {})
  local cmd = { 'dotnet', 'build', project.path, '-c', 'Debug', '-nologo', '-v', 'q', '-clp:NoSummary' }
  vim.system(cmd, { text = true, cwd = project.dir }, vim.schedule_wrap(function(res)
    local function with_dll(fn)
      if target_paths[project.path] then return fn(target_paths[project.path]) end
      local q = { 'dotnet', 'msbuild', project.path, '-getProperty:TargetPath', '-p:Configuration=Debug' }
      vim.system(q, { text = true, cwd = project.dir }, vim.schedule_wrap(function(r)
        local dll = vim.trim(r.stdout or '')
        if r.code ~= 0 or dll == '' then return notify('Could not find the built assembly of ' .. project.name, vim.log.levels.ERROR) end
        target_paths[project.path] = dll
        fn(dll)
      end))
    end

    vim.api.nvim_echo({ { '' } }, false, {})
    if res.code == 0 then return with_dll(on_built) end
    local output = (res.stdout or '') .. (res.stderr or '')
    local errors = build_errors(output)
    if #errors == 0 then
      local tail = vim.list_slice(vim.split(vim.trim(output), '\n'), math.max(1, #vim.split(vim.trim(output), '\n') - 15))
      return notify('Build failed:\n' .. table.concat(tail, '\n'), vim.log.levels.ERROR)
    end
    vim.fn.setqflist({}, 'r', { title = 'Build errors', items = errors })
    vim.ui.select({ 'Show errors', 'Run anyway (last successful build)' }, {
      prompt = ('Build has %d error%s'):format(#errors, #errors == 1 and '' or 's'),
    }, function(choice)
      if choice == 'Show errors' then
        vim.cmd 'copen'
      elseif choice then
        with_dll(on_built)
      end
    end)
  end))
end

-- ============================================================
-- Run / Debug / Hot reload
-- ============================================================

local last_launch -- { project = csproj path, mode = 'run' | 'debug' | 'watch' }

local function stop_debug_session(after)
  if dap.session() then
    dap.terminate { on_done = vim.schedule_wrap(after) }
  else
    after()
  end
end

local function launch(root, project, mode)
  last_launch = { project = project.path, mode = mode }
  local env, profile = app_env(root, project)
  local args = app_args(root, profile)

  if mode == 'debug' then
    return build(project, function(dll)
      local config = {
        type = 'coreclr',
        request = 'launch',
        name = 'Debug ' .. project.name,
        program = dll,
        cwd = project.dir,
        env = env,
        args = vim.split(args, '%s+', { trimempty = true }),
        stopAtEntry = false,
        justMyCode = true,
      }
      stop_term(app_term, function()
        stop_debug_session(function()
          new_debug_console(project.name)
          dap.run(config)
        end)
      end)
    end)
  end

  local cmd = mode == 'watch' and 'dotnet watch --project ' .. vim.fn.shellescape(project.path) .. ' --no-launch-profile'
    or 'dotnet run --project ' .. vim.fn.shellescape(project.path) .. ' --no-launch-profile'
  if args ~= '' then cmd = cmd .. ' -- ' .. args end
  vim.cmd 'silent! wall'
  stop_debug_session(function()
    stop_term(app_term, function()
      if app_term then app_term:shutdown() end
      app_term = new_term(98, {
        cmd = cmd,
        dir = project.dir,
        env = term_env(env),
        display_name = (mode == 'watch' and 'Hot reload: ' or 'Run: ') .. project.name .. (profile and (' (' .. profile.name .. ')') or ''),
      })
      last_console = 'run'
    end)
  end)
end

local function start(mode)
  local root = project_root()
  if not root then return notify('Not in a .NET project', vim.log.levels.WARN) end
  startup_project(root, function(project) launch(root, project, mode) end)
end

--- Shift+F10: start the last run/debug again (restart when it is still running)
local function rerun(mode)
  if not last_launch then return start(mode or 'run') end
  local root = project_root() or vim.fs.dirname(last_launch.project)
  launch(root, project_info(last_launch.project), mode or last_launch.mode)
end

local function app_running() return term_running(app_term) or (dap.session() ~= nil and dap.session().config.type == 'coreclr') end

--- Ctrl+F2: stop the debug session / running app, otherwise a running dotnet command
local function stop()
  if dap.session() then
    dap.terminate()
  elseif term_running(app_term) then
    stop_term(app_term)
  elseif term_running(tool_term) then
    stop_term(tool_term)
  else
    notify 'Nothing is running'
  end
end

-- ============================================================
-- Tests (dotnet test, debuggable by attaching to the test host)
-- ============================================================

local function node_name(node)
  local name = node:field('name')[1]
  return name and vim.treesitter.get_node_text(name, 0)
end

--- Namespace.Class.Method of the test under the cursor (method nil: whole class)
local function test_under_cursor(class_only)
  local ok, node = pcall(vim.treesitter.get_node)
  if not ok or not node then return vim.fn.expand '%:t:r' end
  local method, classes, namespaces = nil, {}, {}
  local cs_types = { class_declaration = true, record_declaration = true, struct_declaration = true }
  while node do
    local t = node:type()
    if t == 'method_declaration' and not method then
      method = node_name(node)
    elseif cs_types[t] then
      table.insert(classes, 1, node_name(node))
    elseif t == 'namespace_declaration' then
      table.insert(namespaces, 1, node_name(node))
    elseif t == 'compilation_unit' then
      for child in node:iter_children() do -- `namespace Foo;` is a sibling of the class
        if child:type() == 'file_scoped_namespace_declaration' then table.insert(namespaces, 1, node_name(child)) end
      end
    end
    node = node:parent()
  end
  if #classes == 0 then return vim.fn.expand '%:t:r' end
  local name = table.concat(namespaces, '.') .. (#namespaces > 0 and '.' or '') .. table.concat(classes, '+')
  if method and not class_only then name = name .. '.' .. method end
  return name
end

local function test_projects(root) return vim.tbl_filter(function(p) return p.test end, projects(root)) end

--- `dotnet test` with an optional filter; debug=true attaches the debugger to the test host
local function run_tests(filter, debug)
  local root = project_root()
  local target
  if filter then
    local project = current_project()
    if not project or not project.test then return notify('This file is not in a test project', vim.log.levels.WARN) end
    target = project.path
  else
    local tests = test_projects(root)
    local has_sln = vim.iter(vim.fs.dir(root)):any(function(name) return is_sln(name) end)
    target = (has_sln or #tests ~= 1) and nil or tests[1].path
  end

  local cmd = 'dotnet test' .. (target and (' ' .. vim.fn.shellescape(target)) or '')
  if filter then cmd = cmd .. ' --filter ' .. vim.fn.shellescape('FullyQualifiedName~' .. filter) end
  local env = { ASPNETCORE_ENVIRONMENT = project_state(root).environment ~= '' and project_state(root).environment or nil }

  local opts = { env = env, name = (debug and 'Debug test: ' or 'Test: ') .. (filter or 'all') }
  if debug then
    -- the test host prints its process id and waits until a debugger is attached
    env.VSTEST_HOST_DEBUG = '1'
    local attached = false
    opts.on_stdout = function(_, _, data)
      if attached then return end
      local pid = table.concat(data, ''):match 'Process Id:%s*(%d+)'
      if not pid then return end
      attached = true
      vim.schedule(function()
        new_debug_console('test ' .. (filter or 'all'))
        dap.run { type = 'coreclr', request = 'attach', name = 'Debug test ' .. (filter or 'all'), processId = tonumber(pid), justMyCode = true }
      end)
    end
  end
  run_tool(root, cmd, opts)
end

-- ============================================================
-- dotnet CLI menu (IntelliJ: Maven/Gradle tool window)
-- ============================================================

--- Argument for commands that take a project/solution: nothing when the root has
--- exactly one, otherwise the current file's project (or the first one)
local function cli_target(root)
  local files = {}
  for name in vim.fs.dir(root) do
    if is_sln(name) or is_csproj(name) then table.insert(files, name) end
  end
  if #files == 1 then return '' end
  local p = current_project() or projects(root)[1]
  return p and (' ' .. vim.fn.shellescape(p.path)) or ''
end

local cli_commands = {
  { 'build', 'Build' },
  { 'clean', 'Clean' },
  { 'restore', 'Restore packages' },
  { 'test', 'Run all tests' },
  { 'publish -c Release', 'Publish (Release)' },
  { 'format', 'Format code (dotnet format)' },
  { 'list package --outdated', 'Outdated packages' },
  { 'list package --vulnerable', 'Vulnerable packages' },
}

local function cli_menu()
  local root = project_root()
  local target = cli_target(root)
  local last = project_state(root).last_tool
  local items = {}
  if term_running(tool_term) then table.insert(items, { stop = true, label = 'Stop: ' .. tool_term.display_name .. '   Ctrl+F2' }) end
  if last then table.insert(items, { cmd = last, label = 'Re-run: ' .. last }) end
  for _, c in ipairs(cli_commands) do
    local verb, rest = c[1]:match '^(%S+)(.*)$'
    table.insert(items, { cmd = 'dotnet ' .. verb .. target .. rest, label = c[2] .. '  —  dotnet ' .. c[1] })
  end
  table.insert(items, { add_package = true, label = 'Add NuGet package…' })
  table.insert(items, { custom = true, label = 'Custom dotnet command…' })

  vim.ui.select(items, {
    prompt = 'dotnet (' .. vim.fn.fnamemodify(root, ':t') .. ')',
    format_item = function(i) return i.label end,
  }, function(choice)
    if not choice then return end
    if choice.stop then return stop_term(tool_term) end
    if choice.add_package then
      local project = current_project() or projects(root)[1]
      return vim.ui.input({ prompt = 'Package (name [--version x]) for ' .. project.name .. ': ' }, function(pkg)
        if pkg and vim.trim(pkg) ~= '' then run_tool(root, 'dotnet add ' .. vim.fn.shellescape(project.path) .. ' package ' .. vim.trim(pkg)) end
      end)
    end
    if choice.custom then
      return vim.ui.input({ prompt = 'dotnet ', default = last and last:gsub('^dotnet ', '') or '' }, function(args)
        if args and vim.trim(args) ~= '' then run_tool(root, 'dotnet ' .. vim.trim(args)) end
      end)
    end
    run_tool(root, choice.cmd)
  end)
end

-- ============================================================
-- Entity Framework Core (dotnet ef)
-- ============================================================

--- Migration ids (newest first) from the folder holding the model snapshot
local function migrations(project)
  local folder
  for name, type in vim.fs.dir(project.dir, { depth = 4, skip = function(dir) return not skip_dirs[vim.fs.basename(dir)] end }) do
    if type == 'file' and name:match 'ModelSnapshot%.cs$' then
      folder = project.dir .. '/' .. vim.fs.dirname(name)
      break
    end
  end
  if not folder then return {} end
  local ids = {}
  for name in vim.fs.dir(folder) do
    local id = name:match '^(%d+_[%w_]+)%.cs$'
    if id then table.insert(ids, id) end
  end
  table.sort(ids, function(a, b) return a > b end)
  return ids
end

local function ef_menu()
  local root = project_root()
  local ef_projects = vim.tbl_filter(function(p) return p.ef end, projects(root))
  if #ef_projects == 0 then return notify('No project references Microsoft.EntityFrameworkCore.Design', vim.log.levels.WARN) end

  local function menu_for(project)
    -- design time runs Program.cs, so give it the app's environment and folder (.env)
    local env = app_env(root, project)
    local base = 'dotnet ef --project ' .. vim.fn.shellescape(project.path) .. ' '
    local function ef(args) run_tool(root, base .. args, { dir = project.dir, env = env, name = 'EF: ' .. args }) end

    local items = {
      { 'Update database (apply migrations)', function() ef 'database update' end },
      { 'Add migration…', function()
        vim.ui.input({ prompt = 'Migration name: ' }, function(name)
          if name and vim.trim(name) ~= '' then ef('migrations add ' .. vim.fn.shellescape(vim.trim(name))) end
        end)
      end },
      { 'Remove last migration (not applied yet)', function() ef 'migrations remove' end },
      { 'List migrations', function() ef 'migrations list' end },
      { 'Update database to migration…', function()
        local ids = vim.list_extend(migrations(project), { '0' })
        vim.ui.select(ids, {
          prompt = 'Migrate database to',
          format_item = function(id) return id == '0' and '0  (revert everything)' or id end,
        }, function(id)
          if id then ef('database update ' .. id) end
        end)
      end },
      { 'SQL script (idempotent)', function() ef 'migrations script --idempotent' end },
      { 'Drop database…', function()
        vim.ui.select({ 'No', 'Yes, drop it' }, { prompt = 'Drop the database of ' .. project.name .. '?' }, function(c)
          if c == 'Yes, drop it' then ef 'database drop --force' end
        end)
      end },
    }
    vim.ui.select(items, {
      prompt = 'EF Core · ' .. project.name,
      format_item = function(i) return i[1] end,
    }, function(choice)
      if choice then choice[2]() end
    end)
  end

  if #ef_projects == 1 then return menu_for(ef_projects[1]) end
  vim.ui.select(ef_projects, { prompt = 'EF Core project', format_item = function(p) return p.name end }, function(p)
    if p then menu_for(p) end
  end)
end

-- ============================================================
-- SDK, language server
-- ============================================================

local function sdk_info()
  local root = project_root() or vim.fn.getcwd()
  local version = vim.trim(vim.system({ 'dotnet', '--version' }, { text = true, cwd = root }):wait().stdout or '')
  local sdks = vim.trim(vim.system({ 'dotnet', '--list-sdks' }, { text = true }):wait().stdout or '')
  local global = vim.fs.find('global.json', { path = root, upward = true })[1]
  notify(
    ('SDK used here: %s%s\n\nInstalled:\n%s\n\nInstall others with pacman (dotnet-sdk-8.0, dotnet-sdk, ...).'):format(
      version,
      global and ('  (pinned by ' .. vim.fn.fnamemodify(global, ':~') .. ')') or '',
      sdks
    )
  )
end

local function remove_unused_usings()
  local last = vim.api.nvim_buf_line_count(0)
  vim.lsp.buf.code_action {
    apply = true,
    range = { start = { 1, 0 }, ['end'] = { last, 0 } },
    filter = function(a)
      local title = a.title:lower()
      return title:find 'unnecessary using' ~= nil and not title:find 'project' and not title:find 'solution'
    end,
  }
end

local function restart_roslyn()
  vim.lsp.enable('roslyn', false)
  vim.defer_fn(function() vim.lsp.enable('roslyn', true) end, 500)
  notify 'Restarting the C# language server'
end

-- ============================================================
-- The menu
-- ============================================================

local function menu()
  local root = project_root()
  if not root then return notify('Not in a .NET project', vim.log.levels.WARN) end
  local all = projects(root)
  local runnable = vim.tbl_filter(function(p) return p.runnable end, all)
  local has_tests = vim.iter(all):any(function(p) return p.test end)
  local has_ef = vim.iter(all):any(function(p) return p.ef end)
  local st = project_state(root)
  local startup = #runnable == 1 and runnable[1] or nil
  for _, p in ipairs(runnable) do
    if p.path == st.startup then startup = p end
  end
  local profile = startup and active_profile(root, startup)
  local in_cs = vim.bo.filetype == 'cs'

  local items = {
    { '  Run…                                Shift+F10 reruns', function() start 'run' end },
    { '  Debug…                              Shift+F9', function() start 'debug' end },
    { '󰑓  Run with hot reload (dotnet watch)', function() start 'watch' end },
  }
  if last_launch then
    local name = vim.fn.fnamemodify(last_launch.project, ':t:r')
    table.insert(items, { '  Restart ' .. name .. ' (' .. last_launch.mode .. ')', function() rerun() end })
    if last_launch.mode ~= 'debug' then table.insert(items, { '  Restart ' .. name .. ' in debugger', function() rerun 'debug' end }) end
  end
  if app_running() then table.insert(items, { '  Stop                                Ctrl+F2', stop }) end
  if term_running(tool_term) then
    table.insert(items, { '  Stop ' .. tool_term.display_name .. (app_running() and '' or '   Ctrl+F2'), function() stop_term(tool_term) end })
  end
  vim.list_extend(items, {
    { '  Show app console / logs             <leader>dc', toggle_console },
    { '  Launch profile…  (' .. (profile and profile.name or 'none') .. ')       <leader>jp', select_profile },
    { '  Environment…  (' .. (st.environment and st.environment ~= '' and st.environment or 'from profile') .. ')', select_environment },
    { '  Run arguments…', edit_run_args },
  })
  if #runnable > 1 then
    table.insert(items, { '  Startup project…  (' .. (startup and startup.name or 'ask') .. ')', function() select_startup(root, runnable) end })
  end
  if has_tests then
    if in_cs then
      vim.list_extend(items, {
        { '󰙨  Test: nearest method', function() run_tests(test_under_cursor()) end },
        { '󰙨  Test: nearest method (debug)', function() run_tests(test_under_cursor(), true) end },
        { '󰙨  Test: this class', function() run_tests(test_under_cursor(true)) end },
        { '󰙨  Test: this class (debug)', function() run_tests(test_under_cursor(true), true) end },
      })
    end
    table.insert(items, { '󰙨  Test: all', function() run_tests() end })
  end
  table.insert(items, { '  dotnet…  (build, clean, restore, publish, packages)', cli_menu })
  if has_ef then table.insert(items, { '  EF Core…  (migrations, database update)', ef_menu }) end
  vim.list_extend(items, {
    { '  .NET SDK…                           <leader>jv', sdk_info },
    { '  Generate… / code actions', function() vim.lsp.buf.code_action() end },
    { '  Remove unnecessary usings           Alt+O', remove_unused_usings },
    { '󰏗  Build', function() run_tool(root, 'dotnet build' .. cli_target(root)) end },
    { '  Pick solution / target (:Roslyn target)', function() vim.cmd 'Roslyn target' end },
    { '  Restart C# language server', restart_roslyn },
    { '  Show language server logs', function() vim.cmd('tabnew ' .. vim.fn.fnameescape(vim.lsp.log.get_filename())) end },
  })

  vim.ui.select(items, {
    prompt = '.NET — ' .. vim.fn.fnamemodify(root, ':t') .. (startup and ('  ·  ' .. startup.name) or ''),
    format_item = function(i) return i[1] end,
  }, function(choice)
    if choice then choice[2]() end
  end)
end

-- ============================================================
-- Keymaps: the Java keys (java.lua, debug.lua) do the .NET thing in .NET projects
-- ============================================================

vim.api.nvim_create_user_command('DotnetProfile', select_profile, { desc = 'Pick the launch profile for this .NET project' })
vim.api.nvim_create_user_command('DotnetSdk', sdk_info, { desc = 'Show the .NET SDKs' })

--- Map `keys` to `fn` in .NET projects and to whatever they did before elsewhere.
--- Runs after startup so java.lua / debug.lua have set their mappings.
local function dotnet_or_previous(keys, fn, desc)
  for _, key in ipairs(keys) do
    local prev = vim.fn.maparg(key, 'n', false, true)
    local fallback = prev.callback
      or (prev.rhs and prev.rhs ~= '' and function() vim.api.nvim_feedkeys(vim.keycode(prev.rhs), 'm', false) end)
    vim.keymap.set('n', key, function()
      if in_dotnet_project() then
        fn()
      elseif fallback then
        fallback()
      end
    end, { desc = desc .. (prev.desc and (' / ' .. prev.desc) or '') })
  end
end

vim.schedule(function()
  dotnet_or_previous({ '<leader>jj' }, menu, '.NET: action menu')
  dotnet_or_previous({ '<leader>jp' }, select_profile, '.NET: pick launch profile')
  dotnet_or_previous({ '<leader>jv' }, sdk_info, '.NET: SDKs')
  dotnet_or_previous({ '<S-F10>', '<F22>' }, function() rerun() end, '.NET: re-run last')
  dotnet_or_previous({ '<S-F9>', '<F21>' }, function() start 'debug' end, '.NET: debug')
  dotnet_or_previous({ '<C-F2>', '<F26>' }, stop, '.NET: stop')
  dotnet_or_previous({ '<leader>dc' }, toggle_console, '.NET: toggle app console')
end)

vim.api.nvim_create_autocmd('LspAttach', {
  callback = function(args)
    local client = vim.lsp.get_client_by_id(args.data.client_id)
    if not client or client.name ~= 'roslyn' then return end
    vim.keymap.set('n', '<A-o>', remove_unused_usings, { buffer = args.buf, desc = 'C#: Remove unnecessary usings' })
  end,
})
