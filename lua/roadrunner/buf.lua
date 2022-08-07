local M = {}

--- Opens a scratch window in a vertical split.
M.open_scratch = function()
    if M.is_visible then
        return
    end

    M.is_visible = true

    if not M.id or not vim.api.nvim_buf_is_loaded(M.id) then
        M.create_scratch()
    end

    local current_window = vim.api.nvim_get_current_win()

    vim.cmd('vsplit')
    vim.cmd('vert res 70')
    local scratch_window = vim.api.nvim_get_current_win()

    vim.api.nvim_win_set_buf(scratch_window, M.id)
    vim.api.nvim_set_current_win(current_window)
end

M.delete = function()
    M.is_visible = false

    if M.id then
        vim.api.nvim_buf_delete(M.id, { force = true })
    end

    M.id = nil
end

--- Creates a scratch buffer.
M.create_scratch = function()
    M.id = vim.api.nvim_create_buf(true, true)
    vim.api.nvim_buf_set_keymap(M.id, 'n', '<C-C>', ':bd!<CR>', { silent = true, noremap = true })
    vim.api.nvim_buf_set_keymap(M.id, 'n', '<ESC>', ':bd!<CR>', { silent = true, noremap = true })

    vim.api.nvim_create_autocmd('BufHidden', {
        group = M.cmd_group,
        buffer = M.id,
        callback = function()
            M.is_visible = false
        end,
    })

    -- There's some really weird flaky behavior with bufdelete and bufunload.
    -- Not really sure how to fix it, though :(
    vim.api.nvim_create_autocmd('BufDelete', {
        group = M.cmd_group,
        buffer = M.id,
        callback = function()
            M.is_visible = false
            M.id = nil
            __RoadRunner.runner.stop_job()
            vim.api.nvim_del_augroup_by_name('RoadRunner')
        end,
    })
end

return M
