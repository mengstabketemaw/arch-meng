-- Java development: eclipse.jdt.ls via nvim-jdtls, with an IntelliJ-style
-- action menu instead of a key for everything.
--
--   <leader>jj   Java menu: run / debug / tests / Maven or Gradle / project JDK / ...
--   <leader>jv   Java version picker (also :JavaVersion)
--   <S-F10>      Re-run last run configuration  (IntelliJ: Shift+F10)
--   <S-F9>       Debug (pick main class)         (IntelliJ: Shift+F9)
--   <C-F2>       Stop                            (IntelliJ: Ctrl+F2)
--   <A-o>        Organize imports
--   crv/crc/crm  Extract variable / constant / method
--
-- Debugger keys (F7/F8/F9...) live in lua/kickstart/plugins/debug.lua.

vim.pack.add { 'https://github.com/mfussenegger/nvim-jdtls' }

local mason_packages = vim.fn.stdpath 'data' .. '/mason/packages'

local function glob_list(pattern)
  local res = vim.fn.glob(pattern, true, true)
  return type(res) == 'table' and res or {}
end

local function notify(msg, level) vim.notify(msg, level or vim.log.levels.INFO, { title = 'Java' }) end

-- ============================================================
-- Project root & per-project state (JDK, run arguments, last build command)
-- ============================================================

-- Prefer the outermost build root (mvnw/gradlew/.git) so multi-module projects
-- get one jdtls workspace, then fall back to the nearest build file.
local root_markers = {
  { 'mvnw', 'gradlew', '.git' },
  { 'pom.xml', 'build.gradle', 'build.gradle.kts', 'settings.gradle', 'settings.gradle.kts', 'build.xml', '.project' },
}

local function project_root(bufnr) return vim.fs.root(bufnr or 0, root_markers) or vim.fn.getcwd() end

local state_file = vim.fn.stdpath 'data' .. '/java-projects.json'

local function load_all_state()
  local f = io.open(state_file, 'r')
  if not f then return {} end
  local ok, data = pcall(vim.json.decode, f:read '*a', { luanil = { object = true } })
  f:close()
  return ok and type(data) == 'table' and data or {}
end

local function project_state(root)
  return load_all_state()[root or project_root()] or {}
end

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
-- Installed JDKs (system, sdkman and IntelliJ-downloaded ones)
-- ============================================================

local function detect_jdks()
  local candidates = {}
  for _, pattern in ipairs { '/usr/lib/jvm/*', '~/.sdkman/candidates/java/*', '~/.jdks/*' } do
    vim.list_extend(candidates, glob_list(vim.fs.normalize(pattern)))
  end
  local jdks, seen = {}, {}
  for _, dir in ipairs(candidates) do
    local real = vim.uv.fs_realpath(dir)
    local release = real and io.open(real .. '/release', 'r')
    if release and vim.fn.executable(real .. '/bin/javac') == 1 and not seen[real] then
      seen[real] = true
      local version = release:read('*a'):match 'JAVA_VERSION="([^"]+)"'
      release:close()
      if version then
        local major = version:match '^1%.(%d+)' or version:match '^(%d+)'
        table.insert(jdks, {
          path = real,
          version = version,
          major = tonumber(major),
          -- jdtls runtime names: JavaSE-1.8, JavaSE-11, JavaSE-17, ...
          name = major == '8' and 'JavaSE-1.8' or ('JavaSE-' .. major),
        })
      end
    elseif release then
      release:close()
    end
  end
  table.sort(jdks, function(a, b) return (a.major or 0) > (b.major or 0) end)
  return jdks
end

local function read_file(path)
  local f = io.open(path, 'r')
  if not f then return nil end
  local content = f:read '*a'
  f:close()
  return content
end

local function major_of(version) return tonumber(version and (version:match '^1%.(%d+)' or version:match '(%d+)')) end

--- Installed JDK for a Java major version: exact match, otherwise the closest newer one
local function jdk_for_major(jdks, major)
  if not major then return nil end
  local best
  for _, jdk in ipairs(jdks) do
    if jdk.major == major then return jdk end
    if jdk.major and jdk.major > major and (not best or jdk.major < best.major) then best = jdk end
  end
  return best
end

--- The JDK the project itself asks for, like IntelliJ does on import:
--- 1. IntelliJ's project SDK (.idea/misc.xml)  2. pom.xml / build.gradle Java version.
--- Matters for old projects: e.g. Spring Boot 2.x pins a Lombok that breaks on new JDKs.
local function auto_jdk(root, jdks)
  local misc = read_file(root .. '/.idea/misc.xml')
  local sdk = misc and misc:match 'project%-jdk%-name="([^"]+)"'
  if sdk then
    for _, jdk in ipairs(jdks) do
      local dir = vim.fn.fnamemodify(jdk.path, ':t')
      if dir == sdk or vim.startswith(dir, sdk .. '.') then return jdk, 'IntelliJ project SDK' end
    end
    local jdk = jdk_for_major(jdks, major_of(sdk))
    if jdk then return jdk, 'IntelliJ project SDK' end
  end

  local pom = read_file(root .. '/pom.xml')
  if pom then
    for _, tag in ipairs { 'java.version', 'maven.compiler.release', 'maven.compiler.source', 'release', 'source' } do
      local version = pom:match('<' .. vim.pesc(tag) .. '>%s*([%d.]+)%s*</')
      local jdk = jdk_for_major(jdks, major_of(version))
      if jdk then return jdk, 'pom.xml' end
    end
  end

  local gradle = read_file(root .. '/build.gradle') or read_file(root .. '/build.gradle.kts')
  if gradle then
    local version = gradle:match 'JavaLanguageVersion%.of%((%d+)%)' -- toolchain
      or gradle:match 'VERSION_1_(%d+)' -- sourceCompatibility = JavaVersion.VERSION_1_8
      or gradle:match 'VERSION_(%d+)'
      or gradle:match 'sourceCompatibility%s*=%s*[\'"]?([%d.]+)'
    local jdk = jdk_for_major(jdks, major_of(version))
    if jdk then return jdk, 'build.gradle' end
  end
end

--- JDK for the project: the one picked in the menu, otherwise the one the project asks for.
--- Returns jdk, reason ('selected' or where it was detected), or nil to use the system default.
local function project_jdk(root)
  root = root or project_root()
  local jdks = detect_jdks()
  local path = project_state(root).jdk
  if path then
    for _, jdk in ipairs(jdks) do
      if jdk.path == path then return jdk, 'selected' end
    end
  end
  return auto_jdk(root, jdks)
end

-- ============================================================
-- jdtls
-- ============================================================

-- per project root: has jdtls finished importing? / run waiting for that
local jdtls_ready, pending_run = {}, {}

local function get_jdtls_config(bufnr)
  local root = project_root(bufnr)
  -- name + hash so two projects with the same folder name don't share a workspace
  local workspace_dir = string.format(
    '%s/jdtls-workspace/%s-%s',
    vim.fn.stdpath 'cache',
    vim.fn.fnamemodify(root, ':t'),
    vim.fn.sha256(root):sub(1, 8)
  )

  -- java-debug (debugging) + vscode-java-test (JUnit) extensions
  local bundles = glob_list(mason_packages .. '/java-debug-adapter/extension/server/com.microsoft.java.debug.plugin-*.jar')
  local excluded = { 'com.microsoft.java.test.runner-jar-with-dependencies.jar', 'jacocoagent.jar' }
  for _, jar in ipairs(glob_list(mason_packages .. '/java-test/extension/server/*.jar')) do
    local name = vim.fn.fnamemodify(jar, ':t')
    -- asm is already part of jdtls; installing it twice makes jdtls log "Failed to load extension bundles"
    if not vim.tbl_contains(excluded, name) and not name:match '^org%.objectweb%.asm' then table.insert(bundles, jar) end
  end

  -- Every installed JDK is offered to jdtls; the project's JDK is the default
  local selected = (project_jdk(root) or {}).path
  -- (jdtls needs unique names: the selected JDK wins, otherwise the first of each version)
  local runtimes, by_name = {}, {}
  for _, jdk in ipairs(detect_jdks()) do
    local existing = by_name[jdk.name]
    if not existing or jdk.path == selected then
      local runtime = { name = jdk.name, path = jdk.path, default = jdk.path == selected or nil }
      if existing then
        runtimes[existing.index] = runtime
        runtime.index = existing.index
      else
        table.insert(runtimes, runtime)
        runtime.index = #runtimes
      end
      by_name[jdk.name] = runtime
    end
  end
  for _, r in ipairs(runtimes) do r.index = nil end

  local config = {
    name = 'jdtls',
    cmd = {
      'jdtls',
      '--jvm-arg=-Xmx2g', -- 4g + a Maven build was too much for a 14 GB laptop
      '--jvm-arg=-javaagent:' .. mason_packages .. '/jdtls/lombok.jar',
      '-data',
      workspace_dir,
    },
    root_dir = root,
    settings = {
      java = {
        signatureHelp = { enabled = true },
        completion = {
          maxResults = 50,
          favoriteStaticMembers = {
            'org.junit.Assert.*',
            'org.junit.jupiter.api.Assertions.*',
            'org.assertj.core.api.Assertions.*',
            'org.mockito.Mockito.*',
          },
          filteredTypes = { 'com.sun.*', 'java.awt.*', 'jdk.swing.*' },
        },
        extensions = { codeActions = { packageName = { generate = { enabled = true } } } },
        configuration = {
          updateBuildConfiguration = 'automatic',
          runtimes = runtimes,
        },
        goto = { definition = { fallback = 'source' } },
        implementCodeAction = { enabled = true },
        format = { enabled = true },
        inlayHints = { parameterNames = { enabled = 'all' } },
        saveActions = { organizeImports = false },
        eclipse = { downloadSources = true },
        maven = { downloadSources = true },
        referencesCodeLens = { enabled = false },
      },
    },
    handlers = {
      -- jdtls reports ServiceReady once the project import is done; runs wait for it
      ['language/status'] = function(_, result)
        if not result then return end
        if result.type == 'Starting' then
          jdtls_ready[root] = false
          vim.api.nvim_echo({ { 'jdtls: ' .. (result.message or ''), 'Comment' } }, false, {})
        elseif result.type == 'ServiceReady' then
          jdtls_ready[root] = true
          vim.api.nvim_echo({ { 'jdtls: ready', 'Comment' } }, false, {})
          local pending = pending_run[root]
          pending_run[root] = nil
          if pending then vim.schedule(pending) end
        end
      end,
    },
    init_options = {
      bundles = bundles,
      extendedClientCapabilities = require('jdtls').extendedClientCapabilities,
    },
  }

  local ok, blink = pcall(require, 'blink.cmp')
  if ok then config.capabilities = blink.get_lsp_capabilities() end

  return config
end

-- Hot code replace on save while debugging (IntelliJ HotSwap)
require('jdtls').setup_dap { hotcodereplace = 'auto', config_overrides = { console = 'integratedTerminal' } }

local function jdtls_client() return vim.lsp.get_clients({ name = 'jdtls' })[1] end

--- Run `fn` from a java buffer that jdtls is attached to (most jdtls commands
--- work on the current buffer).
local function with_java_buffer(fn)
  local client = jdtls_client()
  if not client then
    notify('Java language server is not running — open a .java file first', vim.log.levels.WARN)
    return
  end
  if vim.lsp.get_clients({ bufnr = 0, name = 'jdtls' })[1] then return fn() end
  for buf in pairs(client.attached_buffers) do
    if vim.api.nvim_buf_is_loaded(buf) then
      return vim.api.nvim_buf_call(buf, fn)
    end
  end
end

-- ============================================================
-- Run / Debug (IntelliJ run configurations)
-- ============================================================

local last_launch -- the last dap configuration started from here

local function short_class(main) return main:match '([^.]+)$' or main end

local function launch(config, debug)
  local dap = require 'dap'
  config = vim.deepcopy(config)
  local root = config.cwd or project_root()
  local st = project_state(root)
  config.noDebug = not debug or nil
  config.name = (debug and 'Debug ' or 'Run ') .. short_class(config.mainClass)
  config.args = st.args or ''
  config.vmArgs = vim.trim(((config.vmArgs or '') .. ' ' .. (st.vmArgs or '')))
  local jdk = project_jdk(root)
  if jdk then config.javaExec = jdk.path .. '/bin/java' end
  last_launch = { config = config, debug = debug }

  local function start() dap.run(config) end
  if dap.session() then
    dap.terminate { on_done = vim.schedule_wrap(start) }
  else
    start()
  end
end

local function client_for(root)
  for _, c in ipairs(vim.lsp.get_clients { name = 'jdtls' }) do
    if c.config.root_dir == root then return c end
  end
end

--- workspace/executeCommand on jdtls; callback(err, result) runs on the main loop
local function jdtls_command(client, command, arguments, callback)
  client:request('workspace/executeCommand', { command = command, arguments = arguments }, function(err, result)
    vim.schedule(function() callback(err, result) end)
  end)
end

local function err_text(err) return err and (err.message or vim.inspect(err)) or '' end

--- Make sure jdtls runs for `root`: if no Java file of the project is open,
--- load one in the background (its FileType autocmd starts jdtls).
local function start_jdtls(root)
  for _, buf in ipairs(vim.api.nvim_list_bufs()) do
    if vim.api.nvim_buf_is_loaded(buf) and vim.bo[buf].filetype == 'java' and project_root(buf) == root then
      return true -- jdtls is already starting for it
    end
  end
  local file = vim.fs.find(function(name) return name:match '%.java$' end, { path = root .. '/src/main/java', type = 'file', limit = 1 })[1]
    or vim.fs.find(function(name) return name:match '%.java$' end, { path = root, type = 'file', limit = 1 })[1]
  if not file then return false end
  local buf = vim.fn.bufadd(file)
  vim.fn.bufload(buf)
  if vim.bo[buf].filetype ~= 'java' then vim.api.nvim_buf_call(buf, function() vim.cmd 'filetype detect' end) end
  return true
end

--- Find the main classes (the one in the current file wins), resolve the
--- classpath of the chosen one and launch it. Unlike jdtls.dap.fetch_main_configs
--- this waits for the project import and reports errors instead of hanging.
local function run_main(debug)
  local root = project_root()
  local client = client_for(root)
  if not client or not jdtls_ready[root] then
    -- queue the run: it starts by itself once jdtls reports ServiceReady
    pending_run[root] = function() run_main(debug) end
    if not client and not start_jdtls(root) then
      pending_run[root] = nil
      return notify('No Java sources found under ' .. root, vim.log.levels.WARN)
    end
    notify(
      (client and 'Java server is still importing the project' or 'Starting the Java server')
        .. ' — the app starts by itself when it is ready.\n(The very first import of a big project can take a few minutes.)'
    )
    local queued = pending_run[root]
    vim.defer_fn(function()
      if pending_run[root] == queued then
        notify(
          'The Java server is still not ready after 3 minutes.\n<leader>jj → "Show jdtls logs" to see why, or "Wipe jdtls cache & restart".',
          vim.log.levels.WARN
        )
      end
    end, 180000)
    return
  end

  local current = vim.fn.expand '%:t:r'
  local answered = false
  notify 'Finding main classes…'
  vim.defer_fn(function()
    if not answered then
      notify(
        'Still waiting for the Java server…\nIf it never finishes: <leader>jj → "Reload project", or "Wipe jdtls cache & restart".',
        vim.log.levels.WARN
      )
    end
  end, 15000)

  local function start(main)
    jdtls_command(client, 'vscode.java.resolveClasspath', { main.mainClass, main.projectName }, function(err, paths)
      if err or not paths then
        return notify(
          ('Could not resolve the classpath of %s:\n%s\nDoes the project build? (<leader>jj → Maven → compile)'):format(main.mainClass, err_text(err)),
          vim.log.levels.ERROR
        )
      end
      local config = {
        type = 'java',
        request = 'launch',
        name = main.mainClass,
        mainClass = main.mainClass,
        projectName = main.projectName,
        cwd = root,
        modulePaths = paths[1],
        classPaths = paths[2],
        console = 'integratedTerminal',
      }
      if project_jdk(root) then return launch(config, debug) end -- launch() sets javaExec
      jdtls_command(client, 'vscode.java.resolveJavaExecutable', { main.mainClass, main.projectName }, function(_, exec)
        config.javaExec = exec
        launch(config, debug)
      end)
    end)
  end

  jdtls_command(client, 'vscode.java.resolveMainClass', {}, function(err, mains)
    answered = true
    if err then return notify('Could not search for main classes:\n' .. err_text(err), vim.log.levels.ERROR) end
    if not mains or #mains == 0 then
      return notify('No main class found. Does the project build? (<leader>jj → Maven → compile)', vim.log.levels.WARN)
    end
    for _, m in ipairs(mains) do
      if short_class(m.mainClass) == current then return start(m) end
    end
    if #mains == 1 then return start(mains[1]) end
    vim.ui.select(mains, {
      prompt = (debug and 'Debug' or 'Run') .. ' main class',
      format_item = function(m) return m.mainClass .. (m.projectName and ('  (' .. m.projectName .. ')') or '') end,
    }, function(choice)
      if choice then start(choice) end
    end)
  end)
end

local function rerun(debug)
  if not last_launch then return run_main(debug or false) end
  launch(last_launch.config, debug == nil and last_launch.debug or debug)
end

local function stop()
  local dap = require 'dap'
  if dap.session() then
    dap.terminate()
  else
    notify 'Nothing is running'
  end
end

local function edit_run_args()
  local root = project_root()
  local st = project_state(root)
  vim.ui.input({ prompt = 'Program arguments: ', default = st.args or '' }, function(args)
    if args == nil then return end
    vim.ui.input({ prompt = 'VM options: ', default = st.vmArgs or '' }, function(vm)
      if vm == nil then return end
      save_project_state(root, { args = args, vmArgs = vm })
      notify 'Run arguments saved for this project'
    end)
  end)
end

-- ============================================================
-- Maven / Gradle (run in a reusable terminal split)
-- ============================================================

local build_term

local function build_tool(root)
  if vim.uv.fs_stat(root .. '/pom.xml') then
    return { name = 'Maven', cmd = vim.uv.fs_stat(root .. '/mvnw') and './mvnw' or 'mvn' }
  end
  for _, f in ipairs { 'build.gradle', 'build.gradle.kts', 'settings.gradle', 'settings.gradle.kts' } do
    if vim.uv.fs_stat(root .. '/' .. f) then
      return { name = 'Gradle', cmd = vim.uv.fs_stat(root .. '/gradlew') and './gradlew' or 'gradle' }
    end
  end
end

local function run_build(root, args)
  local tool = build_tool(root)
  if not tool then return notify('No pom.xml or build.gradle in ' .. root, vim.log.levels.WARN) end
  save_project_state(root, { last_build = args })

  local env
  local jdk = project_jdk(root)
  if jdk then env = { JAVA_HOME = jdk.path, PATH = jdk.path .. '/bin:' .. vim.env.PATH } end

  if build_term then build_term:shutdown() end
  local Terminal = require('toggleterm.terminal').Terminal
  build_term = Terminal:new {
    id = 99, -- fixed id so it never takes over the Ctrl+t / Alt+t terminals
    cmd = tool.cmd .. ' ' .. args,
    dir = root,
    env = env,
    direction = 'horizontal',
    close_on_exit = false,
    display_name = tool.name .. ': ' .. args,
    on_open = function() vim.cmd 'stopinsert' end,
  }
  build_term:open(15)
  vim.cmd 'wincmd p' -- keep editing while it builds
end

local maven_goals = {
  { 'clean', 'Clean' },
  { 'compile', 'Compile' },
  { 'test', 'Run all tests' },
  { 'package', 'Package' },
  { 'package -DskipTests', 'Package (skip tests)' },
  { 'clean install', 'Clean install' },
  { 'clean install -DskipTests', 'Clean install (skip tests)' },
  { 'verify', 'Verify' },
  { 'dependency:tree', 'Dependency tree' },
  { 'dependency:resolve -U', 'Re-download dependencies (-U)' },
}

local gradle_tasks = {
  { 'clean', 'Clean' },
  { 'build', 'Build' },
  { 'build -x test', 'Build (skip tests)' },
  { 'test', 'Run all tests' },
  { 'dependencies', 'Dependencies' },
  { '--refresh-dependencies build', 'Refresh dependencies' },
}

local function build_menu()
  local root = project_root()
  local tool = build_tool(root)
  if not tool then return notify('No pom.xml or build.gradle in ' .. root, vim.log.levels.WARN) end
  local is_maven = tool.name == 'Maven'

  local items = {}
  local last = project_state(root).last_build
  if last then table.insert(items, { args = last, label = 'Re-run: ' .. last }) end

  for _, g in ipairs(is_maven and maven_goals or gradle_tasks) do
    table.insert(items, { args = g[1], label = g[2] .. '  —  ' .. g[1] })
  end

  -- Spring Boot run goal when the build file mentions it
  local build_file = root .. (is_maven and '/pom.xml' or '/build.gradle')
  local f = io.open(build_file, 'r') or io.open(root .. '/build.gradle.kts', 'r')
  if f then
    if f:read('*a'):find('spring%-boot') then
      local goal = is_maven and 'spring-boot:run' or 'bootRun'
      table.insert(items, 2, { args = goal, label = 'Spring Boot run  —  ' .. goal })
    end
    f:close()
  end

  -- Tests of the current file only
  if vim.bo.filetype == 'java' then
    local class = vim.fn.expand '%:t:r'
    local args = is_maven and ('test -Dtest=' .. class) or ('test --tests "*' .. class .. '"')
    table.insert(items, { args = args, label = 'Test ' .. class .. '  —  ' .. args })
  end
  table.insert(items, { custom = true, label = 'Custom ' .. (is_maven and 'goal' or 'task') .. '…' })

  vim.ui.select(items, {
    prompt = tool.name .. ' (' .. vim.fn.fnamemodify(root, ':t') .. ')',
    format_item = function(i) return i.label end,
  }, function(choice)
    if not choice then return end
    if choice.custom then
      vim.ui.input({ prompt = tool.cmd .. ' ', default = last or '' }, function(args)
        if args and args ~= '' then run_build(root, args) end
      end)
    else
      run_build(root, choice.args)
    end
  end)
end

-- ============================================================
-- Project JDK (IntelliJ: Project Structure → SDK)
-- ============================================================

local function apply_jdk_choice(root, choice, auto_label)
  save_project_state(root, { jdk = choice.path or vim.NIL })
  local client = jdtls_client()
  if choice.auto then
    notify(auto_label .. (client and ' (restarting jdtls)' or ''))
    if client then with_java_buffer(function() require('jdtls.setup').restart() end) end
    return
  end
  notify(('Java version: %s (%s) — used by jdtls, run/debug and Maven/Gradle'):format(choice.name, choice.version))
  if client then
    -- keep jdtls' runtime list in sync and switch it live
    for _, r in ipairs(client.config.settings.java.configuration.runtimes or {}) do
      if r.name == choice.name then r.path = choice.path end
      r.default = r.path == choice.path or nil
    end
    with_java_buffer(function() require('jdtls').set_runtime(choice.name) end)
  end
end

--- Small floating window to pick the project's Java version.
--- j/k (or 1-9) to move, <CR> to select, q/<Esc> to close.
local function select_jdk(opts)
  opts = opts or {}
  local root = project_root()
  local jdks = detect_jdks()
  if #jdks == 0 then return notify('No JDKs found in /usr/lib/jvm, ~/.sdkman or ~/.jdks', vim.log.levels.WARN) end
  local current = project_state(root).jdk
  local detected, source = auto_jdk(root, jdks)
  local auto_label = detected and ('Auto · %s %s (from %s)'):format(detected.name, detected.version, source)
    or 'Auto · system default (not detected)'

  local items = vim.list_extend({ { auto = true } }, jdks)
  local home = vim.env.HOME
  local lines, cursor = {}, 1
  for i, j in ipairs(items) do
    local active = j.auto and not current or j.path == current
    if active then cursor = i end
    local text = j.auto and auto_label
      or ('%-10s %-9s %s'):format(j.name:gsub('JavaSE%-', 'Java '), j.version, (j.path:gsub('^' .. vim.pesc(home), '~')))
    lines[i] = (' %d  %s %s '):format(i, active and '●' or ' ', text)
  end

  local width = 0
  for _, l in ipairs(lines) do width = math.max(width, vim.fn.strdisplaywidth(l)) end
  local title = ' Java version · ' .. vim.fn.fnamemodify(root, ':t') .. ' '
  width = math.max(width, vim.fn.strdisplaywidth(title) + 2)

  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.bo[buf].modifiable = false
  vim.bo[buf].bufhidden = 'wipe'
  local win = vim.api.nvim_open_win(buf, true, {
    relative = 'editor',
    width = width,
    height = #lines,
    row = math.floor((vim.o.lines - #lines) / 2) - 1,
    col = math.floor((vim.o.columns - width) / 2),
    style = 'minimal',
    border = 'rounded',
    title = title,
    title_pos = 'center',
    footer = opts.reason and (' ' .. opts.reason .. ' ') or ' <CR> select · q close ',
    footer_pos = 'center',
  })
  vim.wo[win].cursorline = true
  vim.wo[win].winhighlight = 'CursorLine:PmenuSel,FloatTitle:Title'
  vim.api.nvim_win_set_cursor(win, { cursor, 0 })

  -- dim the paths, highlight the active entry
  local ns = vim.api.nvim_create_namespace 'java-jdk-picker'
  for i, l in ipairs(lines) do
    local path_col = l:find(' [~/]')
    if path_col and not items[i].auto then vim.hl.range(buf, ns, 'Comment', { i - 1, path_col }, { i - 1, #l }) end
    local dot = l:find('●', 1, true)
    if dot then vim.hl.range(buf, ns, 'DiagnosticOk', { i - 1, dot - 1 }, { i - 1, dot + 2 }) end
  end

  local function close()
    if vim.api.nvim_win_is_valid(win) then vim.api.nvim_win_close(win, true) end
  end
  local function choose(index)
    local choice = items[index or vim.api.nvim_win_get_cursor(win)[1]]
    close()
    if choice then apply_jdk_choice(root, choice, auto_label) end
  end
  local map = function(key, fn) vim.keymap.set('n', key, fn, { buffer = buf, nowait = true }) end
  map('<CR>', function() choose() end)
  map('q', close)
  map('<Esc>', close)
  for i = 1, math.min(#items, 9) do
    map(tostring(i), function() choose(i) end)
  end
  vim.api.nvim_create_autocmd('WinLeave', { buffer = buf, once = true, callback = close })
end

-- First time a project is opened: if neither a saved choice nor .idea / the
-- build file says which JDK to use, ask once with the picker.
local asked = {}
local function ensure_project_jdk(root)
  if asked[root] or not build_tool(root) then return end
  asked[root] = true
  if project_jdk(root) or project_state(root).jdk_asked then return end
  save_project_state(root, { jdk_asked = true })
  vim.schedule(function() select_jdk { reason = 'Java version not detected — pick one' } end)
end

-- ============================================================
-- The menu
-- ============================================================

local function menu()
  local dap_ok, dap = pcall(require, 'dap')
  local running = dap_ok and dap.session() ~= nil
  local jdk, jdk_source = project_jdk()
  local tool = build_tool(project_root())
  local jdtls = function(fn) return function() with_java_buffer(fn) end end

  local items = {
    { '  Run…                                Shift+F10 reruns', function() run_main(false) end },
    { '  Debug…                              Shift+F9', function() run_main(true) end },
  }
  if last_launch then
    table.insert(items, { '  Re-run ' .. short_class(last_launch.config.mainClass), function() rerun(false) end })
    table.insert(items, { '  Re-debug ' .. short_class(last_launch.config.mainClass), function() rerun(true) end })
  end
  if running then table.insert(items, { '  Stop                                Ctrl+F2', stop }) end
  table.insert(items, { '  Show app console / logs             <leader>dc', function() vim.cmd 'DapConsole' end })
  vim.list_extend(items, {
    { '  Run arguments / VM options…', edit_run_args },
    { '󰙨  Test: nearest method (debuggable)', jdtls(function() require('jdtls').test_nearest_method() end) },
    { '󰙨  Test: this class (debuggable)', jdtls(function() require('jdtls').test_class() end) },
    { '󰙨  Test: pick…', jdtls(function() require('jdtls').pick_test() end) },
  })
  if tool then table.insert(items, { '  ' .. tool.name .. '…', build_menu }) end
  vim.list_extend(items, {
    { '  Java version…  (' .. (jdk and (jdk.name .. ' ' .. jdk.version .. (jdk_source == 'selected' and '' or ', auto')) or 'system default') .. ')       <leader>jv', select_jdk },
    { '  Generate… (constructor, getters/setters, toString, override)', function() vim.lsp.buf.code_action { context = { only = { 'source' }, diagnostics = {} } } end },
    { '  Organize imports                    Alt+O', jdtls(function() require('jdtls').organize_imports() end) },
    { '󰏗  Build project', jdtls(function() require('jdtls').compile 'full' end) },
    { '  Reload project (after pom/gradle changes)', jdtls(function() require('jdtls').update_projects_config { select_mode = 'all' } end) },
    { '  Restart Java language server', jdtls(function() require('jdtls.setup').restart() end) },
    { '󰃢  Wipe jdtls cache & restart (fixes weird errors)', jdtls(function() require('jdtls.setup').wipe_data_and_restart() end) },
    { '  Show jdtls logs', function() vim.cmd 'JdtShowLogs' end },
  })

  vim.ui.select(items, {
    prompt = 'Java — ' .. vim.fn.fnamemodify(project_root(), ':t') .. (jdtls_ready[project_root()] == false and '  (server still importing…)' or ''),
    format_item = function(i) return i[1] end,
  }, function(choice)
    if choice then choice[2]() end
  end)
end

-- ============================================================
-- Keymaps & attach
-- ============================================================

require('which-key').add { { '<leader>j', group = 'Java' } }

vim.keymap.set('n', '<leader>jj', menu, { desc = 'Java: action menu' })
vim.keymap.set('n', '<leader>jv', select_jdk, { desc = 'Java: pick Java version (JDK)' })
vim.api.nvim_create_user_command('JavaVersion', function() select_jdk() end, { desc = 'Pick the Java version (JDK) for this project' })
for _, key in ipairs { '<S-F10>', '<F22>' } do -- some terminals send F22 for Shift+F10
  vim.keymap.set('n', key, function() rerun(false) end, { desc = 'Java: re-run last' })
end
for _, key in ipairs { '<S-F9>', '<F21>' } do
  vim.keymap.set('n', key, function() run_main(true) end, { desc = 'Java: debug…' })
end
for _, key in ipairs { '<C-F2>', '<F26>' } do
  vim.keymap.set('n', key, stop, { desc = 'Stop running app / debug session' })
end

local function jdtls_on_attach(_, bufnr)
  local jdtls = require 'jdtls'
  local map = function(keys, func, desc, mode)
    vim.keymap.set(mode or 'n', keys, func, { buffer = bufnr, desc = 'Java: ' .. desc })
  end

  map('<A-o>', jdtls.organize_imports, 'Organize imports')
  map('crv', function() jdtls.extract_variable() end, 'Extract variable')
  map('crv', function() jdtls.extract_variable(true) end, 'Extract variable', 'v')
  map('crc', function() jdtls.extract_constant() end, 'Extract constant')
  map('crc', function() jdtls.extract_constant(true) end, 'Extract constant', 'v')
  map('crm', function() jdtls.extract_method(true) end, 'Extract method', 'v')
end

vim.api.nvim_create_autocmd('FileType', {
  pattern = 'java',
  callback = function(args)
    local config = get_jdtls_config(args.buf)
    config.on_attach = jdtls_on_attach
    require('jdtls').start_or_attach(config, nil, { bufnr = args.buf })
    ensure_project_jdk(project_root(args.buf))
  end,
})
