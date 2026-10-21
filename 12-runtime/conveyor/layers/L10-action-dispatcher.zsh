#!/data/data/com.termux/files/usr/bin/zsh
# L10: Context-Aware Action Dispatcher
awk '
function sigmoid(z) { return 1.0 / (1.0 + exp(-z)); }
{
    if ($0 ~ /^L9_SEMANTIC/) l9 = $2;
}
END {
    L10_dispatcher = sigmoid((l9 * 0.5) - 0.2)
    printf "L10_DISPATCH=%.4f\n", L10_dispatcher
}'
