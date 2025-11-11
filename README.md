<!-- [![Clarity Logo](./assets/logo-clarity-squared.png)](./) -->
<p align="center">
  <img src="assets/logo-clarity-squared.png" alt="Clarity Logo" width="600" />
</p>

# Clarity

**Web3 platform for decentralized treasury management and crypto investment vaults.**
_Built using Django (REST API), PostgreSQL (DB), Docker Compose (dev/prod stack), and designed for a decoupled frontend._

---

## 🚀 Overview

Clarity is a platform specialized in creating and managing crypto investment vaults, tailored for DAOs and active investors in the DeFi space.
Main features include:
- Modern backend using Django + Django REST Framework
- Centralized API for vaults, profiles, operations, etc.
- Easy integration with smart contracts (_contracts/_)
- Docker-ready stack for fast development and deployment
- Clear split for integrating React, Next.js, or any modern frontend

---

## 🛠️ Technologies

- **Backend:** Django, Django REST Framework, Gunicorn
- **Database:** PostgreSQL
- **Frontend:** (to be completed—React, Next.js, etc.)
- **Smart Contracts:** Solidity, Hardhat/Foundry (to be completed)
- **Containerization:** Docker, Docker Compose

---

## 📦 Project Structure

```bash
.
├── backend # Django core + REST API
│ ├── Clarity
│ └── api
├── frontend # Modern frontend connected to the API
├── contracts # Smart contracts (Solidity/Foundry/Hardhat)
├── docker-compose.yml # Multi-service orchestration
├── requirements/ # Modular Python requirements
├── .env # Sensitive config (not versioned)
├── README.md
└── LICENSE
```


---

## ⚡ Quick Start

Clone the repo
```bash
git clone git@github.com:louislbd/clarity.git
cd clarity
```

Add and configure .env at the project root (see .env.example)
```bash
cp .env.example .env
```

Launch everything with Docker Compose
```bash
docker-compose up --build
```

Backend available at **http://localhost:8000**
Frontend: to be completed based on chosen stack

---

## 🌐 API Endpoints (examples)

- `/api/vaults/` – Access vaults
- `/api/investors/` – Manage investors
- `/api/transactions/` – Transaction history and actions
- _Interactive documentation coming soon_

---

## 📄 License
This project is released under the Apache-2.0 license.
See [LICENSE](./LICENSE) for details.
