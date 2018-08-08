PORTS=( 27018 27050 27051 27052 27053 27054 27055 27100 27101 27102 )

for PORT in ${PORTS[@]}; do
    mongo --port $PORT --eval "db.adminCommand({shutdown:1})" &>/dev/null & 
done