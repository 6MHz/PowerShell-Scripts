."$PSScriptRoot\SimpleSelectClass.ps1"
function Open-ItemSelect(
    [Parameter(Mandatory)]$Data,
    [int]$Depth,
    [string]$LastAttr
) {
    $s = [SimpleItemSelect]::new()
    if ($LastAttr) {
        $s.lastAttr = $LastAttr
    }
    if ($Depth) {
        $s.depth = $Depth
    }
    $s.addData($Data)
    $s.open()
    return @{
        last = $s.getLastSelected();
        item = $s.getLastSelected();
    }
}
function Open-PropSelect(
    [Parameter(Mandatory)]$Data,
    [int]$Depth
) {
    $s = [SimpleItemSelect]::new()
    if ($Depth) {
        $s.depth = $Depth
    }
    $s.addData($Data)
    $s.open()
    return @{
        last = $s.getLastSelected();
        item = $s.getLastSelected();
    }
}