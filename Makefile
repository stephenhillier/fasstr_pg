make hydat:
	cd scripts && ./00_load_hydat.sh

setupdb:
	docker-compose exec db /bin/bash -c "cd /scripts && ./01_setup_db.sh"

installfunctions:
	docker-compose exec db /bin/bash -c "cd /scripts && ./02_install_functions.sh"

psql:
	docker-compose exec db /bin/bash -c "psql postgres://fasstr:test_pw@localhost:5432/fasstr"
