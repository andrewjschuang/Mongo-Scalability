PORTS=( 27018 27050 27051 27052 27053 27054 27055 27100 27101 27102 )

for PORT in "${PORTS[@]}"; do
    lsof -n -i4TCP:$PORT | grep LISTEN | awk '{ print $2 }' | xargs kill &> /dev/null
done