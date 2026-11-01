# FreeFire2D

Protótipo 2D de sobrevivência em arena feito com Godot 4.

## Abrir o projeto
1. Instale o Godot 4.x.
2. No Project Manager, escolha **Import**.
3. Selecione este repositório após cloná-lo ou a pasta que contém `project.godot`.
4. Abra e execute a cena principal.

## Estrutura
- `project.godot`: configuração do projeto.
- `scenes/Main.tscn`: cena inicial.
- `scripts/Main.gd`: montagem do mapa e interface.
- `scripts/Player.gd`: movimento, vida, armadura e disparo.
- `scripts/Bullet.gd`: projétil.
- `scripts/Loot.gd`: itens coletáveis.
- `scripts/SafeZone.gd`: círculo da zona segura.
- `scripts/AssetGenerator.gd`: texturas simples geradas por código.

## Estado atual
Este é um protótipo inicial. Ainda não é um battle royale completo: não há inimigos/partidas online, inventário completo, áudio, arte final ou exportação Android configurada. O fluxo de validação automática verifica a importação e a análise dos recursos com Godot headless.
