local M = {}

M.parse_command = function(cmd)
    for i, item in pairs(cmd) do
        -- Only special case %, other wildcards aren't really relevant.
        if item[1] == '%' then
            cmd[i] = vim.api.nvim_buf_get_name(0)
        end
    end
    if #cmd < 1 then
        return 'echo "No command specified!"'
    elseif #cmd == 1 then
        return cmd[1]
    end

    return vim.fn.join(cmd, ' ')
end

M.get_cwd = function(cmd)
    local Path = require('plenary.path')
    local util = require('lspconfig.util')

    local cwd = vim.loop.cwd() or ''
    for _, arg in pairs(cmd) do
        local maybe_path = Path:new(arg)
        if maybe_path:is_path() or maybe_path.is_dir() then
            cwd = util.find_git_ancestor(arg) or vim.loop.cwd()
        end
    end

    return cwd
end

return M
