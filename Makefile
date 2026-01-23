.PHONY: setup help status clean

help:
	@echo "Psono Zero-Touch Commands"
	@echo "========================="
	@echo "make setup    - Instala tudo automaticamente (Docker, Senhas, Psono)"
	@echo "make status   - Mostra o status dos containers"
	@echo "make clean    - Remove containers e volumes (CUIDADO: Deleta dados)"

setup:
	@chmod +x scripts/setup.sh
	@./scripts/setup.sh

status:
	@cd docker && sudo docker compose ps

clean:
	@cd docker && sudo docker compose down -v
