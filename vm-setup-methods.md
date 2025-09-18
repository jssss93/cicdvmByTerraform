# Azure VM 초기 설정 방법들

## 🎯 현재 프로젝트에서 사용 가능한 방법들

### 1. **Custom Data (Cloud-init) - 현재 사용 중** ✅

**위치**: `modules/virtual-machines/main.tf` (라인 32-41, 136, 188)

```hcl
# 스크립트 템플릿 사용
custom_data = base64encode(templatefile("${path.module}/scripts/install-azcli-linux.sh", {
  custom_script = var.custom_script_linux
}))
```

**장점**:
- VM 생성과 동시에 실행
- 빠른 초기화
- 로그 확인 가능

**단점**:
- 한 번만 실행 (재부팅 시 재실행 안됨)
- 스크립트 크기 제한 (64KB)

### 2. **VM Extensions - 현재 구현됨** ✅

**위치**: `modules/virtual-machines/main.tf` (라인 278-307)

```hcl
# Windows 확장 예시
windows_vm_extensions = {
  "IIS-Install" = {
    publisher            = "Microsoft.Compute"
    type                 = "CustomScriptExtension"
    type_handler_version = "1.10"
    settings = {
      "commandToExecute" = "powershell -Command \"Install-WindowsFeature -name Web-Server -IncludeManagementTools\""
    }
    protected_settings = {}
  }
}

# Linux 확장 예시
linux_vm_extensions = {
  "DockerInstall" = {
    publisher            = "Microsoft.Azure.Extensions"
    type                 = "DockerExtension"
    type_handler_version = "1.0"
    settings = {}
    protected_settings = {}
  }
}
```

**장점**:
- 재실행 가능
- 관리 편리
- Azure Portal에서 확인 가능

**단점**:
- VM 생성 후 별도 실행
- 추가 시간 소요

### 3. **Packer + Custom Images (추가 구현 가능)**

미리 구성된 이미지를 만드는 방법:

```hcl
# Packer 템플릿 예시 (packer.pkr.hcl)
source "azure-arm" "ubuntu" {
  client_id       = var.client_id
  client_secret   = var.client_secret
  tenant_id       = var.tenant_id
  subscription_id = var.subscription_id
  
  managed_image_resource_group_name = "rg-packer-images"
  managed_image_name               = "ubuntu-with-azcli"
  
  os_type         = "Linux"
  image_publisher = "Canonical"
  image_offer     = "0001-com-ubuntu-server-noble"
  image_sku       = "24_04-lts-gen2"
  
  location = "Korea Central"
  vm_size  = "Standard_B2s"
}

build {
  sources = ["source.azure-arm.ubuntu"]
  
  provisioner "shell" {
    script = "install-azcli.sh"
  }
}
```

### 4. **Azure Automation DSC (추가 구현 가능)**

지속적인 구성 관리:

```hcl
resource "azurerm_virtual_machine_extension" "dsc" {
  name                 = "DSC"
  virtual_machine_id   = azurerm_windows_virtual_machine.main.id
  publisher            = "Microsoft.Powershell"
  type                 = "DSC"
  type_handler_version = "2.80"
  
  settings = jsonencode({
    "wmfVersion" = "latest"
    "configuration" = {
      "url" = "https://example.com/dsc-config.zip"
      "script" = "ConfigureServer.ps1"
      "function" = "ConfigureServer"
    }
  })
}
```

### 5. **Azure Policy Guest Configuration (추가 구현 가능)**

정책 기반 구성 관리:

```hcl
resource "azurerm_policy_assignment" "vm_config" {
  name                 = "vm-baseline-config"
  scope                = azurerm_resource_group.main.id
  policy_definition_id = "/providers/Microsoft.Authorization/policyDefinitions/xxx"
  
  parameters = jsonencode({
    "configurationName" = {
      "value" = "BaselineConfiguration"
    }
  })
}
```

## 🔄 각 방법의 실행 시점

| 방법 | 실행 시점 | 재실행 | 용도 |
|------|-----------|--------|------|
| **Custom Data** | VM 첫 부팅 시 | ❌ | 기본 소프트웨어 설치 |
| **VM Extensions** | VM 생성 후 | ✅ | 추가 구성 및 관리 |
| **Custom Images** | 이미지 생성 시 | ❌ | 표준화된 이미지 |
| **DSC** | 지속적 | ✅ | 구성 관리 |
| **Policy** | 지속적 | ✅ | 컴플라이언스 |

## 💡 현재 프로젝트에서 추가할 수 있는 방법들

### A. **Ansible Playbook 실행**

```hcl
# terraform.tfvars에서
custom_script_linux = "
curl -fsSL https://raw.githubusercontent.com/your-repo/ansible-setup.sh | bash
ansible-playbook -i localhost, -c local /tmp/vm-setup.yml
"
```

### B. **Docker Compose 자동 실행**

```hcl
custom_script_linux = "
curl -fsSL https://raw.githubusercontent.com/your-repo/docker-compose.yml -o /opt/docker-compose.yml
cd /opt && docker-compose up -d
"
```

### C. **Application 자동 배포**

```hcl
custom_script_windows = "
git clone https://github.com/your-repo/app.git C:\\app
cd C:\\app && .\\deploy.ps1
"
```

## 🚀 권장 조합

**현재 프로젝트에서 권장하는 방식**:

1. **Custom Data**: 기본 소프트웨어 설치 (Azure CLI, Docker 등)
2. **VM Extensions**: 애플리케이션별 구성
3. **사용자 정의 스크립트**: 환경별 특수 설정

이렇게 조합하면 가장 유연하고 강력한 VM 초기화가 가능합니다! 🎯
