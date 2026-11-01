# FreeFire 3D Prototype

Projeto independente em Godot 4.3, orientado para Android em paisagem e jogabilidade 3D em terceira pessoa. A branch `main` e o protótipo 2D original permanecem preservados; todo o trabalho 3D fica nesta pasta e na branch `rebuild-3d`.

## Sistemas implementados
- Soldados militares 3D mid-poly, rigados em Skeleton3D com materiais PBR; animações retargetadas de idle, caminhada e corrida; câmera em terceira pessoa e controles por toque.
- Movimento, corrida, salto, mira, recarga e disparo contínuo; recoil, inclinação de recarga e movimento da arma durante o salto.
- Cinco classes de arma com modelos GLB próprios: rifle de assalto, pistola, escopeta, submetralhadora e rifle de precisão, com dano, cadência e reservas independentes.
- Colete com absorção de dano, mochila com aumento de reservas, kits médicos e caixas de munição.
- Bots armados com rifle, perseguição, verificação de linha de visão, disparos, locomoção animada e queda ao serem eliminados.
- Zona segura que diminui ao longo da partida e causa dano fora dos limites.
- Construções com entradas, interiores mobiliados, mezanino e rampa de acesso ao segundo piso.
- Terreno, estradas, árvores, veículos, iluminação pública, placas e mobiliário interno com modelos 3D importados.
- HUD com vida, colete, munição, inimigos restantes, zona segura e estado da partida.
- Fluxos de CI separados para importar/testar o projeto 3D e exportar o APK Android.

## Limitações que continuam abertas
Este ainda é um protótipo de produção, não um jogo completo nem uma cópia visual de Free Fire. A cena integra soldados militares mid-poly rigados (Male Soldier 02/03/04, licença MIT), clips retargetados de idle/caminhada/corrida, cinco modelos GLB de armas e carros, árvores, iluminação e mobiliário Kenney CC0. O disparo usa som sintetizado e os passos usam áudio CC0. O resultado ainda não equivale ao nível visual de Free Fire: as armas são modelos low-poly, o mapa ainda é pequeno e faltam animações de combate completas. Mira, recarga, recoil e salto têm movimentos procedurais da arma; não são animações mocap completas de braços e corpo.

Ainda são necessários:
- Modelos de maior detalhe para armas, veículos e cenário, com materiais e otimização de qualidade comercial.
- Animações de corpo completas para mira, tiro, recarga, salto, reação a dano e morte, além de transições entre estados.
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
Os cenários e props usados nesta etapa são do catálogo Kenney, publicados sob CC0 1.0. Os soldados Male Soldier 02/03/04 são de models.codelove.in, licenciados sob MIT; manter a licença incorporada nos arquivos GLB e consultar https://models.codelove.in/licensing/. Os modelos de armas vêm do FPS Asset Kit / OpenGameArt, sob CC0. Os passos vêm do pacote Fantozzi Footsteps (CC0); o efeito de disparo atual é sintetizado pelo jogo. O pipeline baixa os recursos antes de importar/exportar. Fonte Kenney: https://github.com/Hidencod/tge-assets e https://kenney.nl/support. Os arquivos baixados não ficam versionados no repositório; execute `.github/scripts/download-kenney-assets.sh` antes de abrir o projeto localmente.

## Abrir e exportar
Importe esta pasta no Godot 4.3 pelo arquivo `project.godot`. Antes da importação local, execute `.github/scripts/download-kenney-assets.sh` na raiz do repositório. O preset Android exporta para ARM64. A compilação Android precisa concluir o fluxo de CI e o APK precisa ser instalado e testado em aparelho real antes de ser considerado pronto.
