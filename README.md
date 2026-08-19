# 🧊 TGthon

> **Smart Fridge & Recipe Management App**

냉장고 속 식재료를 체계적으로 관리하고, 보유 재료를 기반으로 레시피를 추천받을 수 있는 **Flutter 기반 스마트 냉장고 관리 애플리케이션**입니다.

냉장고에 어떤 재료가 있는지 한눈에 확인하고, 식재료를 효율적으로 소비할 수 있도록 **냉장고 관리 → 레시피 추천 → 할 일 관리**를 하나의 앱에서 제공합니다.

---

## ✨ Features

### 🧊 Smart Fridge

냉장고에 보관 중인 식재료를 등록하고 관리할 수 있습니다.

* 식재료 등록 및 삭제
* 식재료 정보 관리
* 냉장고 내부 식재료 조회
* 보유 식재료를 기반으로 한 요리 탐색
* 식재료 소비 관리

---

### 🍳 Recipe Recommendation

현재 보유하고 있는 식재료를 기반으로 만들 수 있는 요리를 확인할 수 있습니다.

* 보유 재료 기반 레시피 추천
* 레시피 상세 정보 확인
* 추천 레시피 정렬
* 보유 재료와 레시피 재료 비교
* 부족한 재료 확인

레시피 관련 로직은 별도의 서비스 계층으로 분리하여 관리하고 있습니다.

```text
RecipeRanker
    ↓
RecipeSortHelper
    ↓
Recipe Recommendation
```

---

### 📝 Todo

요리 및 식재료와 관련된 할 일을 관리할 수 있습니다.

* 할 일 추가
* 할 일 확인
* 할 일 완료 관리
* 일상적인 식재료 관리와 Todo 연계

---

## 🏗️ Architecture

프로젝트는 기능별로 코드를 분리하여 유지보수하기 쉽도록 구성했습니다.

```text
lib/
├── core/
│
├── data/
│
├── features/
│   └── shell/
│       └── main_shell.dart
│
├── models/
│   ├── api/
│   ├── fridge_item.dart
│   ├── menu_rec.dart
│   ├── recipe.dart
│   └── unified_recipe.dart
│
├── screens/
│   ├── fridge/
│   │   └── fridge_page.dart
│   │
│   ├── home/
│   │
│   ├── recipes/
│   │   ├── recipes_page.dart
│   │   └── recipe_detail_page.dart
│   │
│   └── todo/
│       └── todo_page.dart
│
├── services/
│   ├── recipe_ranker.dart
│   └── recipe_sort_helper.dart
│
├── widgets/
│
├── app.dart
├── firebase_options.dart
└── main.dart
```

### 주요 계층

| Layer      | 역할                         |
| ---------- | -------------------------- |
| `screens`  | 각 화면의 UI 및 사용자 interaction |
| `models`   | 식재료, 레시피, 추천 데이터 모델        |
| `services` | 레시피 추천 및 정렬 등의 비즈니스 로직     |
| `widgets`  | 여러 화면에서 재사용되는 UI 컴포넌트      |
| `data`     | 데이터 접근 및 데이터 관련 처리         |
| `features` | 앱의 주요 기능 단위                |
| `core`     | 프로젝트 전반에서 사용하는 공통 기능       |

---

## 🛠️ Tech Stack

### Frontend

* **Flutter**
* **Dart**
* Material 3

### Backend / Database

* **Firebase**

  * Firebase Authentication
  * Cloud Firestore

### 주요 Packages

```yaml
firebase_core
firebase_auth
cloud_firestore
material_design_icons_flutter
cupertino_icons
```

개발 및 테스트 환경에서는 다음 패키지도 사용합니다.

```yaml
flutter_test
fake_cloud_firestore
flutter_lints
```

현재 프로젝트는 Dart SDK `^3.8.1` 환경을 기준으로 구성되어 있습니다.

---

## 🔥 Firebase

TGthon은 Firebase를 backend infrastructure로 사용합니다.

애플리케이션 시작 시 Firebase를 초기화하고 Firebase Authentication을 통해 사용자를 인증합니다.

현재 초기 실행 과정에서는 **Anonymous Authentication**을 사용하여 사용자별 데이터를 구분할 수 있도록 구성되어 있습니다.

```text
Flutter App
     │
     ├── Firebase Authentication
     │       └── Anonymous User
     │
     └── Cloud Firestore
             ├── Fridge Data
             ├── Recipe Data
             └── User Data
```

> ⚠️ Firebase 설정은 프로젝트 환경에 따라 별도로 구성해야 합니다.

---

## 🚀 Getting Started

### 1. Clone

```bash
git clone https://github.com/wmfrjdna630/TGthon.git
cd TGthon
```

### 2. Flutter dependencies

```bash
flutter pub get
```

### 3. Firebase configuration

Firebase 프로젝트를 생성한 후 FlutterFire 설정을 적용합니다.

```bash
flutterfire configure
```

필요한 Firebase 서비스:

* Firebase Authentication
* Cloud Firestore

Authentication에서 **Anonymous sign-in**을 활성화해야 합니다.

### 4. Run

연결된 디바이스 또는 Emulator에서 실행합니다.

```bash
flutter run
```

웹에서 실행하려면:

```bash
flutter run -d chrome
```

---

## 📱 Supported Platforms

Flutter 프로젝트 구조상 다음 플랫폼을 대상으로 구성되어 있습니다.

* Android
* iOS
* Web
* Windows
* macOS

현재 Firebase 설정에는 Android, iOS, macOS, Web, Windows 환경이 구성되어 있으며 Linux는 별도로 설정되지 않은 상태입니다.

---

## 🖼️ Screens

### Home

애플리케이션의 메인 화면입니다.

### Fridge

냉장고에 보유하고 있는 식재료를 확인하고 관리합니다.

### Recipes

현재 보유한 식재료를 활용할 수 있는 레시피를 확인합니다.

### Todo

식재료 및 요리와 관련된 할 일을 관리합니다.

---

## 🔄 Application Flow

```text
            ┌──────────────┐
            │    Home      │
            └──────┬───────┘
                   │
       ┌───────────┼───────────┐
       │           │           │
       ▼           ▼           ▼
 ┌──────────┐ ┌──────────┐ ┌──────────┐
 │  Fridge  │ │ Recipes  │ │   Todo   │
 └────┬─────┘ └────┬─────┘ └──────────┘
      │             │
      │             ▼
      │      ┌──────────────┐
      └─────►│ Recommendation│
             └──────────────┘
                    │
                    ▼
             ┌──────────────┐
             │ Recipe Detail│
             └──────────────┘
```

---

## 📊 Recipe Recommendation

레시피 추천은 단순히 전체 레시피를 보여주는 방식이 아니라, 사용자가 가지고 있는 식재료와 레시피의 재료 정보를 비교하여 적합한 레시피를 찾는 것을 목표로 합니다.

기본적인 흐름은 다음과 같습니다.

```text
User's Fridge
      │
      ▼
Available Ingredients
      │
      ▼
Recipe Matching
      │
      ▼
Ranking / Sorting
      │
      ▼
Recommended Recipes
```

관련 로직은 `services/recipe_ranker.dart` 및 `services/recipe_sort_helper.dart`에서 관리합니다.

---

## 🎯 Project Goals

TGthon의 목표는 단순한 냉장고 기록 앱을 넘어,

> **"집에 있는 식재료를 기준으로 무엇을 먹을지 결정해주는 서비스"**

를 만드는 것입니다.

사용자는 냉장고에 있는 식재료를 일일이 검색하지 않아도 현재 보유 재료를 기반으로 만들 수 있는 요리를 확인할 수 있고, 이를 통해 식재료를 보다 효율적으로 소비할 수 있습니다.

---

## 🗺️ Roadmap

* [x] Flutter 기반 앱 구조 구축
* [x] Firebase 연동
* [x] Firebase Authentication 연동
* [x] 냉장고 화면 구현
* [x] 레시피 화면 구현
* [x] 레시피 상세 화면 구현
* [x] Todo 화면 구현
* [x] 레시피 정렬/추천 로직 구현
* [ ] 식재료 유통기한 관리
* [ ] 유통기한 임박 알림
* [ ] 레시피 추천 알고리즘 고도화
* [ ] 사용자 맞춤형 레시피 추천
* [ ] 영양 정보 연동
* [ ] 식재료 소비 통계
* [ ] 스마트 냉장고 / IoT 연동

---

## 🔐 Security

Firebase 관련 설정 파일이나 API credential을 Git repository에 직접 추가할 때는 주의해야 합니다.

특히 다음과 같은 민감한 정보는 Git에 업로드하지 않는 것을 권장합니다.

```text
.env
service account keys
private keys
server credentials
```

Firebase의 client-side configuration과 서버용 secret은 서로 다른 수준의 보안 관리가 필요하므로, 배포 환경에서는 Firebase 공식 보안 가이드와 Firestore Security Rules를 함께 사용하는 것을 권장합니다.

---

## 🧪 Testing

Flutter test framework를 사용하며, Firestore 관련 테스트에는 `fake_cloud_firestore`를 사용할 수 있도록 구성되어 있습니다.

```bash
flutter test
```

---

## 📂 Project Status

> 🚧 **Active Development**

현재 TGthon은 기능 구현 및 구조 개선이 진행 중인 프로젝트입니다.

일부 기능과 UI는 향후 변경될 수 있습니다.

---

## 📄 License

현재 별도의 오픈소스 라이선스가 지정되어 있지 않습니다.

프로젝트를 외부에 공개하거나 다른 사람이 자유롭게 사용·수정할 수 있도록 할 계획이라면 추후 `MIT`, `Apache-2.0` 등의 라이선스를 추가하는 것을 권장합니다.

---

## 👨‍💻 Author

**wmfrjdna630**

GitHub:
https://github.com/wmfrjdna630/TGthon

---

## ⭐ Contributing

프로젝트 개선을 위한 Issue 및 Pull Request를 환영합니다.

1. Repository Fork
2. Feature Branch 생성
3. 변경사항 구현
4. Test 실행
5. Pull Request 생성

```bash
git checkout -b feature/new-feature
```

---

## 💡 About TGthon

TGthon은 **냉장고에 있는 재료를 중심으로 식생활을 관리하는 것**을 목표로 합니다.

```text
"What's in my fridge?"
        ↓
"What can I cook?"
        ↓
"Let's cook it."
        ↓
"Don't waste the ingredients."
```

**Manage your fridge. Discover your recipes. Reduce food waste. 🧊🍳**
