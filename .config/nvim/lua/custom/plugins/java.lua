-- Java development support: eclipse.jdt.ls via nvim-jdtls
-- Provides IntelliJ-like features: refactoring, code generation,
-- organize imports, JUnit test running/debugging, and more.

vim.pack.add { 'https://github.com/mfussenegger/nvim-jdtls' }

require('which-key').add {
  { '<leader>j', group = 'Java', mode = 'n' },
  { '<leader>d', group = 'Debug/Run', mode = 'n' },
}

local mason_packages = vim.fn.stdpath('data') .. '/mason/packages'

-- Robust glob that always returns a list of paths (handles both list and
-- string returns that occur across Neovim builds).
local function glob_list(pattern)
  local res = vim.fn.glob(pattern, 1)
  if type(res) == 'string' and res ~= '' then
    return vim.split(res, '\n', { plain = true, trimempty = true })
  end
  return type(res) == 'table' and res or {}
end

-- Build the jdtls language server config. `start_or_attach` is invoked
-- once per java buffer, so the config is (re)created lazily.
local function get_jdtls_config()
  local root = vim.fs.root(0, {
    'gradlew',
    'mvnw',
    '.git',
    'build.xml',
    'pom.xml',
    'build.gradle',
    'build.gradle.kts',
    'settings.gradle',
    'settings.gradle.kts',
    '.project',
    '.classpath',
  })
  root = root or vim.fn.getcwd()
  local project_name = vim.fn.fnamemodify(root, ':p:h:t')
  local workspace_dir = vim.fn.stdpath('cache') .. '/jdtls-workspace/' .. project_name

  -- Bundles enable debugging (java-debug) and running/debugging JUnit
  -- tests (vscode-java-test) with the DAP utilities already configured.
  local bundles = {
    unpack(glob_list(mason_packages .. '/java-debug-adapter/extension/server/com.microsoft.java.debug.plugin-*.jar')),
  }
  local excluded = {
    'com.microsoft.java.test.runner-jar-with-dependencies.jar',
    'jacocoagent.jar',
  }
  for _, jar in ipairs(glob_list(mason_packages .. '/java-test/extension/server/*.jar')) do
    local fname = vim.fn.fnamemodify(jar, ':t')
    if not vim.tbl_contains(excluded, fname) then
      table.insert(bundles, jar)
    end
  end

  -- Location of the lombok jar that ships with the mason jdtls package.
  local lombok_jar = mason_packages .. '/jdtls/lombok.jar'

  local config = {
    name = 'jdtls',
    cmd = {
      'jdtls',
      '--jvm-arg=-Xmx4g',
      '--jvm-arg=-javaagent:' .. lombok_jar,
      '-data',
      workspace_dir,
    },
    root_dir = root,
    settings = {
      java = {
        -- IntelliJ-style behavior
        signatureHelp = { enabled = true },
        completion = {
          maxResults = 50,
          favoriteStaticMembers = {
            'org.junit.Assert.*',
            'org.junit.jupiter.api.Assertions.*',
            'org.assertj.core.api.Assertions.*',
            'org.mockito.Mockito.*',
          },
          filteredTypes = {
            'com.sun.*',
            'java.awt.*',
            'jdk.swing.*',
          },
        },
        extensions = {
          codeActions = { packageName = { generate = { enabled = true } } },
        },
        configuration = {
          updateBuildConfiguration = 'automatic',
        },
        goto = { definition = { fallback = 'source' } },
        implementCodeAction = { enabled = true },
        format = { enabled = true },
        -- Show parameter name hints, like IntelliJ's parameter info
        inlayHints = { parameterNames = { enabled = 'all' } },
        saveActions = { organizeImports = false },
        -- Fetch sources when available (enables jump-to-source of deps)
        eclipse = { downloadSources = true },
        maven = { downloadSources = true },
      },
    },
    init_options = {
      bundles = bundles, -- java-debug + java-test extensions
      extendedClientCapabilities = require('jdtls').extendedClientCapabilities,
    },
  }

  -- Hook blink.cmp capabilities into the client
  local ok, blink = pcall(require, 'blink.cmp')
  if ok then
    config.capabilities = blink.get_lsp_capabilities()
  end

  return config
end

-- Register and configure the java debug adapter (hot-code-replace like
-- IntelliJ's hot swap, automatic main-class discovery, JUnit debugging).
require('jdtls').setup_dap({ hotcodereplace = 'auto', config_overrides = {
  console = "integratedTerminal"
} })

-- Per-buffer keymaps & commands for nvim-jdtls extras.
local function jdtls_on_attach(client, bufnr)
  local jdtls = require 'jdtls'
  local map = function(keys, func, desc, mode)
    mode = mode or 'n'
    vim.keymap.set(mode, keys, func, { buffer = bufnr, desc = 'Jdtls: ' .. desc })
  end

  -- Organize imports (IntelliJ: Ctrl+Alt+O)
  map('<A-o>', jdtls.organize_imports, 'Organize imports')

  -- Refactoring (IntelliJ: Ctrl+Alt+V / C / M)
  map('crv', function() jdtls.extract_variable() end, 'Extract variable')
  map('crv', function() jdtls.extract_variable(true) end, 'Extract variable', 'v')
  map('crc', function() jdtls.extract_constant() end, 'Extract constant')
  map('crc', function() jdtls.extract_constant(true) end, 'Extract constant', 'v')
  map('crm', function() jdtls.extract_method(true) end, 'Extract method', 'v')

  -- Tests (IntelliJ: run class / method)
  map('<leader>df', function() jdtls.test_class() end, 'Run test class')
  map('<leader>dn', function() jdtls.test_nearest_method() end, 'Run nearest test method')
  map('<leader>dp', function() jdtls.pick_test() end, 'Pick test to run')

  -- Build & server management (IntelliJ: Build = Ctrl+F9)
  map('<leader>jb', function() jdtls.compile 'full' end, 'Build project')
  map('<leader>jc', function() jdtls.compile 'incremental' end, 'Compile incremental')
  map('<leader>jr', function() vim.cmd 'JdtRestart' end, 'Restart JDT server')
  map('<leader>js', function() jdtls.set_runtime() end, 'Switch Java runtime (JdtSetRuntime)')

end

vim.api.nvim_create_autocmd('FileType', {
  pattern = 'java',
  callback = function()
    local config = get_jdtls_config()
    config.on_attach = jdtls_on_attach
    require('jdtls').start_or_attach(config)
  end,
})
