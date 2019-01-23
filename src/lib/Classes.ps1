Class CINotifications : Attribute {
    [string[]]$Address
    [string[]]$SuccessAddress
    [bool]$SendOnSuccess

    CINotifications ([string[]]$Address, [bool]$SendOnSuccess, [string[]]$SuccessAddress) {
        $This.Address       = $Address
        $This.SendOnSuccess = $SendOnSuccess
        if ($null -ne $SuccessAddress) {
            $This.SuccessAddress = $SuccessAddress
        } else {
            $This.SuccessAddress = $Address
        }
    }

    CINotifications ([string[]]$Address, [bool]$SendOnSuccess) {
        $This.Address        = $Address
        $This.SendOnSuccess  = $SendOnSuccess
        $This.SuccessAddress = $Address
    }

    CINotifications ([string[]]$Address) {
        $This.Address        = $Address
        $This.SendOnSuccess  = $false
        $This.SuccessAddress = $Address
    }
}

Class CITeamsNotifications : Attribute {
    [string]$Uri

    CITeamsNotifications ([string[]]$Uri) {
        $This.Uri = $Uri
    }
}

Class ValidatePathExistsAttribute : System.Management.Automation.ValidateArgumentsAttribute {
    [void] Validate ([object]$Arguments, [System.Management.Automation.EngineIntrinsics]$engineIntrinsics) {
        $Path = $Arguments
        if([string]::IsNullOrWhiteSpace($Path)) {
            Throw [System.ArgumentNullException]::new()
        }
        if(-not (Test-Path -Path $Path)) {
            Throw [System.IO.FileNotFoundException]::new()
        }
    }
}
