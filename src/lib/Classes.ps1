Class CINotifications : Attribute {
    [string[]]$Address
    [string[]]$SuccessAddress
    [int]$SendOnSuccess

    CINotifications ([string[]]$Address, [int]$SendOnSuccess = 0, [string[]]$SuccessAddress) {
        $This.Address       = $Address
        $This.SendOnSuccess = $SendOnSuccess
        if ($null -ne $SuccessAddress) {
            $This.SuccessAddress = $SuccessAddress
        } else {
            $This.SuccessAddress = $Address
        }
    }

    CINotifications ([string[]]$Address, [int]$SendOnSuccess = 0) {
        $This.Address        = $Address
        $This.SendOnSuccess  = $SendOnSuccess
        $This.SuccessAddress = $Address
    }
}

Class CITeamsNotifications : Attribute {
    [string]$Uri

    CITeamsNotifications ([string[]]$Uri) {
        $This.Uri = $Uri
    }
}
