. $PSScriptRoot\shared.ps1
$Scripts = Get-ChildItem $ScriptPath -Filter '*.ps1' -Recurse
$Rules   = Get-ScriptAnalyzerRule

Describe 'Testing all Scripts against PSScriptAnalyzer Static Code Analysis' {
    foreach ($Script in $Scripts) {
        Context "Testing File - $($Script.Name)" {
            foreach ($Rule in $Rules) {
                It "$($Script.Name) passes the PSScriptAnalyzer Rule $Rule" {
                    (Invoke-ScriptAnalyzer -Path $Script.FullName -IncludeRule $Rule).Count | Should Be 0
                }
            }
        }
    }
}
