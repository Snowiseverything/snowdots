set -gx EDITOR "zed --wait"

function oc
    opencode session continue 2>/dev/null; or opencode
end