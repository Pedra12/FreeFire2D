# FreeFire 3D Prototype

Projeto independente em Godot 4.3, orientado para Android em paisagem e jogabilidade 3D em terceira pessoa. A branch `main` e o protótipo 2D original permanecem preservados; todo o trabalho 3D fica nesta pasta e na branch `rebuild-3d`.

## Sistemas implementados
- Personagens militares 3D rigados de 80 ossos e materiais PBR, com animações compatíveis, câmera em terceira pessoa, mira aproximada e controle por toque.
- Movimento, corrida, salto, recarga, disparo contínuo e poses procedurais de braços e pernas.
- Cinco classes de arma com modelos GLB próprios: rifle de assalto, pistola, escopeta, submetralhadora e rifle de precisão, com dano, cadência e reservas independentes.
- Colete com absorção de dano, mochila com aumento de reservas, kits médicos e caixas de munição.
- Bots com perseguição, verificação de linha de visão, disparos, animação simples e queda ao serem eliminados.
- Zona segura que diminui ao longo da partida e causa dano fora dos limites.
- Construções com paredes segmentadas, entradas e espaços internos acessíveis.
- Terreno, estradas, árvores, veículos, iluminação pública, placas e mobiliário interno com modelos 3D importados.
- HUD com vida, colete, munição, inimigos restantes, zona segura e estado da partida.
- Fluxos de CI separados para importar/testar o projeto 3D e exportar o APK Android.

## Limitações que continuam abertas
Este ainda é um protótipo de produção, não um jogo completo nem uma cópia visual de Free Fire. A cena integra soldados militares mid-poly rigados (modelos Male Soldier 02/03/04, licença MIT), clips retargetados de idle/caminhada/corrida, armas GLB e som de disparo CC0, além de carros, árvores, iluminação e mobiliário 3D CC0 da Kenney. O nível de detalhe ainda não equivale a um jogo comercial como Free Fire; os modelos de armas de combate e o conjunto completo de animações de combate ainda precisam ser integrados. As armas de combate ainda precisam de modelos próprios adequados; alguns movimentos usam fallback procedural e a disponibilidade de clips varia por personagem.

Ainda são necessários:
- Modelos 3D externos de qualidade para personagens, armas, veículos e cenário, com rig, materiais e licenças compatíveis.
- Animações completas e integradas a um esqueleto: idle, corrida, salto, mira, tiro, recarga, troca de arma e morte.
- Mapa maior com interiores mobiliados, escadas, andares, cobertura, colisões e pontos de interesse.
- Veículos dirigíveis, inventário completo, acessórios, diferentes níveis de armadura e balanceamento de loot.
- Áudio de armas, passos, ambiente, interface e efeitos sonoros; efeitos visuais de tiro, impacto, fumaça e explosões.
- Perfil de desempenho em aparelhos Android reais, ajuste de resolução, sombras, LOD, memória e taxa de quadros.
- Testes prolongados de partidas contra bots e correção de bugs antes de iniciar a arquitetura de multiplayer online.

## Ordem de desenvolvimento
1. Estabilizar importação, execução e exportação Android.
2. Testar em aparelho real e corrigir controles, desempenho, colisões e balanceamento dos bots.
3. Integrar assets 3D e animações licenciados, substituindo as malhas temporárias.
4. Completar mapa, inventário, áudio e efeitos.
5. Só então projetar multiplayer online com servidor autoritativo, sincronização, salas e proteção contra trapaças.

## Assets e licenças
Os cenários e props usados nesta etapa são do catálogo Kenney, publicados sob CC0 1.0. Os soldados Male Soldier 02/03/04 são de models.codelove.in, licenciados sob MIT; manter a licença incorporada nos arquivos GLB e consultar https://models.codelove.in/licensing/. As armas e o áudio de disparo vêm do FPS Asset Kit / OpenGameArt, sob CC0. O pipeline baixa os recursos antes de importar/exportar. Fonte Kenney: https://github.com/Hidencod/tge-assets e https://kenney.nl/support. Os arquivos baixados não ficam versionados no repositório; execute `.github/scripts/download-kenney-assets.sh` antes de abrir o projeto localmente.

## Abrir e exportar
Importe esta pasta no Godot 4.3 pelo arquivo `project.godot`. Antes da importação local, execute `.github/scripts/download-kenney-assets.sh` na raiz do repositório. O preset Android exporta para ARM64. A compilação Android precisa concluir o fluxo de CI e o APK precisa ser instalado e testado em aparelho real antes de ser considerado pronto.
