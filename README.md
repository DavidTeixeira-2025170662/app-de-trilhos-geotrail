# 📱 Geotrail — App Flutter com SQLite
Este projeto é uma aplicação Flutter desenvolvida para testar e implementar uma base de dados local utilizando **SQLite**.  
Inclui funcionalidades de criação e listagem de **Favoritos** e **Caminhadas**, servindo como base para o desenvolvimento futuro da aplicação Geotrail.
## 🚀 Funcionalidades Atuais
### ✔️ Favoritos
- Inserção de favoritos com timestamp automático.
- Listagem dos favoritos guardados na base de dados.
### ✔️ Caminhadas
- Inserção de caminhadas com distância e trilho associado.
- Listagem das caminhadas guardadas.
- Estrutura preparada para evoluir para um histórico completo.
## 🗂️ Estrutura da Base de Dados
A aplicação utiliza SQLite com duas tabelas principais:

### **Tabela: favoritos**
| Campo | Tipo | Descrição |
|-------|------|-----------|
| id | INTEGER PRIMARY KEY | Identificador único |
| trilhoId | INTEGER | ID do trilho |
| data | TEXT | Data/hora da criação |

### **Tabela: caminhadas**
| Campo | Tipo | Descrição |
|-------|------|-----------|
| id | INTEGER PRIMARY KEY | Identificador único |
| trilhoId | INTEGER | ID do trilho percorrido |
| distancia | REAL | Distância percorrida |
| data | TEXT | Data/hora da caminhada |
## 🛠️ Tecnologias Utilizadas
- **Flutter**
- **Dart**
- **SQLite**
- **VS Code**
- **Android Emulator (Pixel 7)**
## ▶️ Como correr o projeto
1. Instalar dependências:
   ```bash
   flutter pub get
2. Instalar o Android Studio: pixel 7
