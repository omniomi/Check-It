[CINotifications('example@example.com',0)]
param()

Describe "Test Set One" {
    Context "Hello World" {
        it "Another thing" {
            $true | Should -Be $false
        }
    }
}

Describe "Test Set Two" {
    Context "Hello World" {
        it "A thing" {
            $false | Should -Be $true
        }
        it "Another thing" {
            $true | Should -Be $true
        }
    }
    Context "Goodbye World" {
        it "A thing" {
            $false | Should -Be $true
        }
        it "Another thing" {
            $true | Should -Be $true
        }
    }
}
