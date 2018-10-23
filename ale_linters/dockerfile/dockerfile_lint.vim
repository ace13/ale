" Author: Alexander Olofsson <alexander.olofsson@liu.se>

call ale#Set('dockerfile_dockerfile_lint_executable', 'dockerfile_lint')
call ale#Set('dockerfile_dockerfile_lint_options', '')

function! ale_linters#dockerfile#dockerfile_lint#GetType(type) abort
    if a:type is? 'error'
        return 'E'
    elseif a:type is? 'warn'
        return 'W'
    endif

    return 'I'
endfunction

function! ale_linters#dockerfile#dockerfile_lint#Handle(buffer, lines) abort
    try
        let l:data = json_decode(join(a:lines, ''))
    catch
        return []
    endtry

    if empty(l:data)
        " Should never happen, but it's better to be on the safe side
        return []
    endif

    let l:messages = []

    for l:type in ['error', 'warn', 'info']
        for l:object in l:data[l:type]['data']
            try
                let l:line = l:object['line']
            catch
                let l:line = -1
            endtry

            let l:message = l:object['message']

            if has_key(l:object, 'description') && l:object['description'] != 'None'
                let l:message = l:message . '. ' . l:object['description']
            endif

            call add(l:messages, {
            \   'lnum': l:line,
            \   'text': l:message,
            \   'type': ale_linters#dockerfile#dockerfile_lint#GetType(l:type),
            \})
        endfor
    endfor

    return l:messages
endfunction

function! ale_linters#dockerfile#dockerfile_lint#GetCommand(buffer) abort
    return '%e' . ale#Pad(ale#Var(a:buffer, 'dockerfile_dockerfile_lint_options'))
    \   . ' -p -j -f'
    \   . ' %t'
endfunction

call ale#linter#Define('dockerfile', {
\   'name': 'dockerfile_lint',
\   'executable_callback': ale#VarFunc('dockerfile_dockerfile_lint_executable'),
\   'command_callback': 'ale_linters#dockerfile#dockerfile_lint#GetCommand',
\   'callback': 'ale_linters#dockerfile#dockerfile_lint#Handle',
\})
