class SimpleSelectBase {
    # UIの高さ
    hidden [int]$height = 0

    # 選択中のインデックス
    hidden [int]$index = 0
    
    # どこまで選択するかのデータの深さ
    [int]$depth = 0

    # 最後に選択したもの
    hidden $last = $null

    # 選択したもの
    hidden $selectedItem = $null

    # データの配列
    hidden $data = @()

    # レンダリングで表示する名前の配列
    hidden [string[]]$itemNames = @()

    # open
    [void]open() {
        $this.index = 0
        $this.selectedItem = $null
        $this.last = $null
        <#
            深さ1以上の時
            もう一度開く際に最初のデータが最後にあるのでそれを取る
        #>
        $this.data = , $this.data[-1] 
        $this.setItemNames()
        while ($this.choice()) {}
        # NoNewLineのままなので改行
        Write-Host
    }
    # レンダリング
    hidden [void]render() {
        Clear-Host
        $texts = ""
        $crrIndex = $this.index
        
        # 選択しているものの表示
        if ($this.itemNames.Count) {
            Write-Host " >$($this.itemNames[$crrIndex])`n"
        }

        # それ以外の表示

        <#
            end
                終了位置
            start
                開始位置
            -3の内訳
                線
                ボタン
                余白    高さが偶数の時、ウィンドウの端とボタンの表記との間に余白が無くなってしまうから
            .5
                表示しているプロパティの下に改行を入れるので、1個あたりの高さが2なので
        #>
        $end = $crrIndex + [Math]::Floor(($this.height - 3) * .5)
        $start = $crrIndex + 1

        for ($i = $start; $i -lt $end; $i++) {
            if ($i -lt $this.itemNames.Count) {
                $texts += "$($this.itemNames[$i])`n`n"
            } else {
                # データの長さ以上なら残りを掛けてbreak
                $texts += "$("`n`n" * ($end - $i))"
                break
            }
        }
        Write-Host $texts -ForegroundColor DarkGray -NoNewline
        # 線とボタン
        $button = ' [W]Up [S]Down [D]Select [A]Back | [E]Exit'
        Write-Host "$('─' * $button.Length)`n$button" -NoNewline #NoNewlineはchoiceを改行させないため
    }
    # データの追加
    [void]addData($data) {
        if ($this.data.Count) {
            # すでにある場合は最初のデータに追加
            $this.data[-1] += $data
        } else {
            # ない場合は追加
            $this.data += , $data
        }
    }
    # choice
    hidden [bool]choice() {
        $crrData = $this.data[0]
        # 長さ0の時即終了
        if (!$crrData.Count) { return $false }
        # 操作する度に高さを更新させる
        $this.height = (Get-Host).UI.RawUI.WindowSize.Height
        $this.render()
        switch (choice /c "wasde" /n) {
            'w' {
                # up
                $this.index -= + !!$this.index
                return $true
            }
            's' {
                # down
                $this.index = [Math]::Min($this.index + 1, $crrData.Count - 1)
                return $true
            }
            'a' {
                # back
                if ($this.data.Count -gt 1) {
                    $this.data = $this.data -ne $crrData
                    $this.index = 0
                    $this.last = $null
                    $this.setItemNames()
                }
                return $true
            }
            'd' {
                # select
                return $this.select()
            }
            'e' {
                # exit
                $this.last = $null
                $this.selectedItem = $null
            }
        }
        return $false
    }
    # select
    hidden [bool]select() {
        $item = $this.getItem()
        if (
            # 深さ0の時
            $this.depth -eq 0 -or
            # 深さとデータの配列の長さが一致する時
            $this.data.Count - 1 -eq $this.depth
        ) {
            $this.selectedItem = $item
            $this.last = $item
            return $false
        }
        $isNext = $this.next($item)
        $this.setItemNames()
        return $isNext
    }
    hidden [System.Object]getItem() {
        return $this.data[0][$this.index]
    }
    hidden [bool]next($item) {
        # 深さがあるときの処理をここにオーバーライド
        return $false
    }
    hidden [void]setItemNames() {
        # オーバーライドする
    }
    [System.Object]getSelected() {
        return $this.selectedItem
    }
    [System.Object]getLastSelected() {
        return $this.last
    }
}
# ファイル、ディレクトリ用
Class SimpleItemSelect: SimpleSelectBase {
    $lastAttr = "Archive"
    hidden [bool]next($item) {
        # 選択したものがディレクトリなら
        if ($item.Attributes.ToString().Contains("Directory")) {
            $this.last = $item
            $this.index = 0
            $path = $this.last.FullName
            $attr = 'Directory'
            if ($this.data.Count -eq $this.depth) {
                $attr = $this.lastAttr
            }
            $this.data = , (Get-ChildItem -Path $path -Attributes $attr) + $this.data
            return $true
        }
        return $false
    }
    hidden [void]setItemNames() {
        $this.itemNames = $this.data[0].Name
    }
}
# ハッシュテーブルなど
Class SimplePropSelect: SimpleSelectBase {
    hidden [System.Object]getItem() {
        return $this.itemNames[$this.index]
    }
    hidden [bool]next($item) {
        $this.last = $item
        $this.index = 0
        $this.data = , $this.data[0][$item] + $this.data
        return $true
    }
    hidden [void]setItemNames() {
        $this.itemNames = $this.data[0].Keys
    }
}
