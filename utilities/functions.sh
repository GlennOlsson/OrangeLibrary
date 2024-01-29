
run_on_container () {
	container=$1
	cmd=$2
	args=${@:3}

	docker compose down -v
}
