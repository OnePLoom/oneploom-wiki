# ADR 0025: 코드와 개발 WIKI의 MIT 라이선스

- 날짜: 2026-11-24
- 설계 상태: `accepted` — 코드와 개발 WIKI에 같은 MIT 라이선스를 적용한다.
- 적용 범위: OnepLoom이 권리를 가진 코드, 설정, 문서와 예시. 외부 자산의 기존 권리를 바꾸는 결정은 아니다.
- 구현 및 검증: 라이선스 파일과 문서 연결을 확인한다. 제품 구현, 의존성 전체의 배포 감사와 릴리스 검증은 별도다.

## 배경

코드와 개발 WIKI는 독립 저장소지만 문서의 설정 예시와 설계가 실제 구현이나 설치 템플릿으로 이어진다. 사용자가 프로젝트에 복사해 수정하는 흐름에서도 적용 조건을 쉽게 확인할 수 있어야 한다.

공개 열람과 재사용 허가는 다르다. GitHub는 공개 저장소의 열람과 fork, 별도 라이선스가 정하는 수정과 재배포 권한을 구분한다. 자체 프로젝트에 부여할 조건과 외부 자료의 권리 확인도 구분한다. [GitHub 라이선스 안내](https://docs.github.com/en/repositories/managing-your-repositorys-settings-and-features/customizing-your-repository/licensing-a-repository).

## 대안

| 안 | 이점 | 비용과 한계 |
| --- | --- | --- |
| 코드와 WIKI 모두 MIT | 문서, 코드와 설정 예시에 같은 조건을 적용. 허가문이 짧고 복사/수정 흐름이 단순함 | 명시적인 특허 허가 조항이 없으며 수정본의 소스 공개를 요구하지 않음 |
| 코드와 WIKI 모두 Apache-2.0 | 기여자의 관련 특허에 대한 명시적 허가와 종료 조건이 있음 | 수정 표시, 기존 고지와 해당 NOTICE 등 재배포 조건을 함께 확인해야 함 |
| 코드 MIT, WIKI CC BY 4.0 | 문서에 출처, 라이선스 링크와 변경 표시 의무가 명확함 | 문서 안의 재사용 코드와 설치 자산을 어떤 조건으로 제공할지 별도 관리가 필요함 |

[MIT 원문](https://opensource.org/license/mit), [Apache-2.0 원문](https://www.apache.org/licenses/LICENSE-2.0), [CC BY 4.0 안내](https://creativecommons.org/licenses/by/4.0/deed.ko)를 비교했다. Creative Commons는 소프트웨어 자체에는 소프트웨어용 라이선스를 사용하고, 문서는 CC로 제공할 수 있다고 설명한다. [CC FAQ](https://creativecommons.org/faq/#can-i-apply-a-creative-commons-license-to-software).

## 결정과 이유

코드와 개발 WIKI 모두 MIT를 사용한다. 상업적 이용, 수정과 재배포를 허용하고, 사본이나 상당한 분량을 재사용할 때 저작권 고지와 허가문을 유지한다. 수정본의 소스 공개는 강제하지 않는다. 상세 허가와 면책은 각 저장소의 LICENSE 원문이 기준이다.

현재는 도입과 유지보수의 단순성이 중요하며 코드와 문서의 라이선스를 나눠 관리할 필요가 확인되지 않았다. 이 조건에 따라 MIT를 선택했다. [Poetry의 LICENSE](https://github.com/python-poetry/poetry/blob/main/LICENSE)와 [FastAPI의 LICENSE](https://github.com/fastapi/fastapi/blob/master/LICENSE)도 코드와 관련 문서를 함께 언급하는 MIT 사용 사례다. 다른 프로젝트가 사용한다는 사실만으로 선택을 정당화하지는 않는다.

## 적용과 확인

- 두 저장소의 루트에 LICENSE를 두고 README에서 연결한다. 표준 허가문은 영어 원문을 유지하고 사용 안내는 한국어로 설명한다.
- 코드, 문서와 템플릿을 실제 배포물이나 프로젝트 적용본에 포함할 때 고지가 빠지지 않도록 설치/배포 검증에서 확인한다. 모든 파일에 중복된 긴 허가문을 삽입하는 방식으로 고정하지 않는다.
- 외부 코드, 라이브러리나 문서를 새로 편입할 때는 해당 자산의 조건과 필요한 고지를 확인한다. OnepLoom의 MIT 선택만으로 외부 자산을 MIT로 바꿀 수 없다.
- 제품을 이용해 생성하거나 수정하는 사용자 프로젝트의 기존 코드와 WIKI에 MIT를 자동 적용하지 않는다. 이 결정은 OnepLoom 자체의 공개 자산에 대한 것이다.
- 라이선스 적용, 원격 게시와 실행 가능한 릴리스는 별도 단계다. 라이선스 파일이 있다는 이유로 제품 검증 완료나 외부 자산의 모든 권리 확인을 보장하지 않는다.

외부 자산 확인 절차는 [모듈 소유 기준의 「라이선스와 저작권」](../../design/module.md#라이선스와%20저작권), 배포 확인은 [검증 조건](../../verification/acceptance.md)이 소유한다.
