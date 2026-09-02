# This macro applies patch to git repository if patch is applicable
# Arguments are path to git repository and path to the git patch

# APPLY_GIT_PATCH: args = `repo_path`, `patch_path`
macro(APPLY_GIT_PATCH repo_path patch_path)
    execute_process(COMMAND git apply -v --ignore-whitespace --check ${patch_path}
            WORKING_DIRECTORY ${repo_path}
            RESULT_VARIABLE SUCCESS
            COMMAND_ECHO STDOUT)

    if(${SUCCESS} EQUAL 0)
        message("Applying git patch ${patch_path} in ${repo_path} repository")
        execute_process(COMMAND git apply -v --ignore-whitespace ${patch_path}
                WORKING_DIRECTORY ${repo_path}
                RESULT_VARIABLE SUCCESS
                COMMAND_ECHO STDOUT)

        if(NOT ${SUCCESS} EQUAL 0)
            message(FATAL_ERROR "\n::error:: failed to apply the patch: ${patch_path}\n")
        endif()
    else()
        # A reused generated source tree may already contain the patch. Prove
        # that state by checking whether it reverses cleanly. Any other failure
        # is a real source/patch mismatch and must not be silently ignored.
        execute_process(COMMAND git apply -v --ignore-whitespace --reverse --check ${patch_path}
                WORKING_DIRECTORY ${repo_path}
                RESULT_VARIABLE REVERSE_SUCCESS
                COMMAND_ECHO STDOUT)

        if(${REVERSE_SUCCESS} EQUAL 0)
            message("Git patch ${patch_path} is already applied in ${repo_path} repository")
        else()
            message(FATAL_ERROR
                    "\n::error:: patch is neither applicable nor already applied: ${patch_path}\n")
        endif()
    endif()
endmacro()
