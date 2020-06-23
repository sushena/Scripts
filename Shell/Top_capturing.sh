# Start a new tmux session in background
tmux new-session -d -s bg-top

# Wait for session to be ready
sleep 5

# Run top
tmux send-keys -t bg-top top Enter

# Wait for top to be ready
sleep 1

# Send t key stroke to top command
tmux send-keys -t bg-top t

# Capture the output of top
tmux pipe-pane -t bg-top 'cat > /tmp/top_out.1'

# Wait for top output
sleep 3

# Send q key stroke to exit top
tmux send-keys -t bg-top q

# Stop output capture
tmux pipe-pane -t bg-top

# Exit tmux session
tmux send-keys -t bg-top exit Enter

# Remove control characters
cat /tmp/top_out.1 | col -b > /tmp/top_out.2

# Remove additional control characters that are not removed from output
sed -e "s/m39;49m1m//g" /tmp/top_out.2 | sed -e "s/m39;49m//g" > /tmp/top_out

/tmp/top_out >> /root/top_output/top_$(date +%F).log