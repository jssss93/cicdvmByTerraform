# VM 스크립트 전달 방식 분석 및 검토 결과

## 🚨 **기존 구현의 문제점들**

### 1. **템플릿 문법 오류**
- **문제**: Cloud-init YAML과 PowerShell 스크립트에서 Terraform 템플릿 문법(`%{ }`) 직접 사용
- **결과**: 템플릿 렌더링 시 문법 오류 발생 가능성 높음

### 2. **복잡한 중첩 구조**
- **문제**: `join()` 함수와 복잡한 리스트 컴프리헨션으로 인한 가독성 저하
- **결과**: 디버깅과 유지보수가 어려움

### 3. **Azure VM 제약사항**
- **문제**: `custom_data`는 단일 base64 인코딩된 스크립트만 전달 가능
- **결과**: 복잡한 파일 전달 방식이 실제로는 작동하지 않을 수 있음

## ✅ **권장하는 올바른 방식들**

### **방식 1: Custom Script Extension 사용 (권장)**

```hcl
# Azure Storage Account에 스크립트 업로드 후 Custom Script Extension 사용
resource "azurerm_virtual_machine_extension" "custom_script" {
  name                 = "custom-script"
  virtual_machine_id   = azurerm_linux_virtual_machine.main[0].id
  publisher            = "Microsoft.Azure.Extensions"
  type                 = "CustomScript"
  type_handler_version = "2.1"

  settings = jsonencode({
    "fileUris" = [
      "https://${azurerm_storage_account.scripts.name}.blob.core.windows.net/scripts/setup.sh",
      "https://${azurerm_storage_account.scripts.name}.blob.core.windows.net/scripts/configure.sh"
    ],
    "commandToExecute" = "bash setup.sh && bash configure.sh"
  })

  protected_settings = jsonencode({
    "storageAccountName" = azurerm_storage_account.scripts.name
    "storageAccountKey"  = azurerm_storage_account.scripts.primary_access_key
  })
}
```

### **방식 2: 단순화된 Custom Data 사용**

```hcl
# terraform.tfvars
custom_script_linux = <<-EOT
#!/bin/bash
echo "사용자 정의 스크립트 실행 시작"

# 스크립트 1 실행
curl -fsSL https://raw.githubusercontent.com/user/repo/main/script1.sh | bash

# 스크립트 2 실행  
curl -fsSL https://raw.githubusercontent.com/user/repo/main/script2.sh | bash

echo "모든 스크립트 실행 완료"
EOT
```

### **방식 3: GitHub Actions + Custom Script Extension**

```yaml
# .github/workflows/deploy-vm-scripts.yml
name: Deploy VM Scripts
on:
  push:
    paths: ['scripts/**']

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - name: Upload scripts to Azure Storage
        run: |
          az storage blob upload-batch \
            --source scripts/ \
            --destination scripts \
            --account-name ${{ secrets.STORAGE_ACCOUNT }}
```

## 🔧 **실제 작동하는 간단한 구현**

### **Linux VM용 (Cloud-init)**

```yaml
#cloud-config
package_update: true
package_upgrade: true

write_files:
  - path: /tmp/user-script.sh
    content: |
      #!/bin/bash
      echo "사용자 정의 스크립트 실행"
      # 여기에 실제 스크립트 내용 작성
    permissions: '0755'

runcmd:
  - /tmp/user-script.sh
```

### **Windows VM용 (PowerShell)**

```powershell
# 사용자 정의 스크립트 실행
$userScript = @"
Write-Host "사용자 정의 스크립트 실행"
# 여기에 실제 스크립트 내용 작성
"@

Invoke-Expression $userScript
```

## 📋 **결론 및 권장사항**

### **현재 구현 방식의 문제점:**
1. ❌ 복잡한 템플릿 문법으로 인한 오류 가능성
2. ❌ Azure VM 제약사항 무시
3. ❌ 디버깅과 유지보수 어려움

### **권장하는 대안:**
1. ✅ **Custom Script Extension** 사용 (가장 안정적)
2. ✅ **단순화된 Custom Data** 사용 (간단한 스크립트용)
3. ✅ **GitHub Actions + Azure Storage** 조합 (CI/CD 통합)

### **즉시 사용 가능한 방식:**
기존 `custom_script_windows`와 `custom_script_linux` 변수를 사용하여 단일 스크립트를 전달하는 것이 가장 안전하고 실용적입니다.

```hcl
# terraform.tfvars
custom_script_linux = <<-EOT
#!/bin/bash
echo "Linux VM 설정 시작"
# 필요한 패키지 설치
apt-get update
apt-get install -y nginx
systemctl enable nginx
systemctl start nginx
echo "Linux VM 설정 완료"
EOT

custom_script_windows = <<-EOT
Write-Host "Windows VM 설정 시작"
# IIS 설치
Enable-WindowsOptionalFeature -Online -FeatureName IIS-WebServerRole -All
Write-Host "Windows VM 설정 완료"
EOT
```

이 방식이 가장 안정적이고 실제로 작동합니다.
