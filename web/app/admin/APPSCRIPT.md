# /admin 시트 읽기 설정

랜딩 데이터는 Apps Script 웹훅(`doPost`)으로 구글 시트에만 적재된다.
`/admin`이 이걸 **되읽으려면** 같은 Apps Script 프로젝트에 `doGet`을 추가하면 된다.
(doGet/doPost는 동일한 웹앱 배포 URL을 공유한다.)

## 1. Apps Script에 doGet 추가

기존 `doPost` 아래에 붙여넣기:

```javascript
function doGet(e) {
  var token = (e.parameter && e.parameter.token) || '';
  var expected = PropertiesService.getScriptProperties().getProperty('READ_TOKEN');
  if (!expected || token !== expected) {
    return ContentService.createTextOutput(JSON.stringify({ ok: false, error: 'unauthorized' }))
      .setMimeType(ContentService.MimeType.JSON);
  }

  var ss = SpreadsheetApp.getActiveSpreadsheet();
  var limit = parseInt(e.parameter.limit, 10) || 1000;

  function readTab(name) {
    var sh = ss.getSheetByName(name);
    if (!sh) return [];
    var lastRow = sh.getLastRow();
    var lastCol = sh.getLastColumn();
    if (lastRow < 2) return [];
    var header = sh.getRange(1, 1, 1, lastCol).getValues()[0];
    var start = lastRow - 1 > limit ? lastRow - limit + 1 : 2; // 최신 limit행만
    var values = sh.getRange(start, 1, lastRow - start + 1, lastCol).getValues();
    return values.map(function (r) {
      var o = {};
      header.forEach(function (h, i) { o[h] = r[i]; });
      return o;
    });
  }

  var out = { ok: true, events: readTab('events'), signups: readTab('signups') };
  return ContentService.createTextOutput(JSON.stringify(out))
    .setMimeType(ContentService.MimeType.JSON);
}
```

## 2. 비밀 토큰 등록

Apps Script 편집기 → **프로젝트 설정(⚙)** → **스크립트 속성** → 속성 추가:

- 속성: `READ_TOKEN`
- 값: 임의의 긴 문자열 (예: `openssl rand -hex 24` 결과)

## 3. 웹앱 재배포

코드 수정 후 **배포 → 배포 관리 → 편집(연필) → 버전: 새 버전 → 배포**.
(새 버전으로 배포하지 않으면 doGet이 반영되지 않는다.)

웹앱 URL은 기존 `SHEETS_WEBHOOK_URL`과 동일하다.

## 4. 환경변수 설정 (encore 랜딩 프로젝트, Vercel)

**서버 전용**(NEXT_PUBLIC 아님):

| 변수 | 값 |
|---|---|
| `ADMIN_PASSWORD` | `/admin` 로그인 비밀번호 |
| `SHEETS_READ_TOKEN` | 위에서 정한 `READ_TOKEN`과 동일 |
| `SHEETS_WEBHOOK_URL` | (기존) Apps Script 웹앱 URL — 읽기에도 재사용 |

> 별도 `SHEETS_READ_URL`을 두면 그 값을 우선 사용한다. 없으면 `SHEETS_WEBHOOK_URL`을 읽기 URL로 쓴다.

설정 후 `/admin` 접속 → 비밀번호 입력 → 데이터 표시.

## 5. 빠른 점검

```bash
curl "<웹앱URL>?token=<READ_TOKEN>&limit=5"
# → {"ok":true,"events":[...],"signups":[...]}
```

## 6. (1회) 과거 /admin 행 정리

앞으로의 `/admin` 트래픽은 서버에서 차단되어 시트에 안 쌓인다.
하지만 차단 이전에 이미 쌓인 행은 남아 있으므로, 아래 함수를 Apps Script에서
**한 번** 실행해 제거한다. (`path`가 `/admin`으로 시작하는 행 삭제)

```javascript
function cleanupAdminRows() {
  var ss = SpreadsheetApp.getActiveSpreadsheet();
  ['events', 'signups'].forEach(function (name) {
    var sh = ss.getSheetByName(name);
    if (!sh) return;
    var lastRow = sh.getLastRow();
    var lastCol = sh.getLastColumn();
    if (lastRow < 2) return;
    var header = sh.getRange(1, 1, 1, lastCol).getValues()[0];
    var pathCol = header.indexOf('path');
    if (pathCol === -1) return;
    var values = sh.getRange(2, 1, lastRow - 1, lastCol).getValues();
    var removed = 0;
    for (var i = values.length - 1; i >= 0; i--) {
      // 아래에서 위로 삭제 — 행 인덱스 밀림 방지
      if (String(values[i][pathCol] || '').indexOf('/admin') === 0) {
        sh.deleteRow(i + 2);
        removed++;
      }
    }
    Logger.log(name + ': ' + removed + '행 삭제');
  });
}
```

실행: 편집기에서 `cleanupAdminRows` 선택 → ▶ 실행. (실행 로그에서 삭제 수 확인)
