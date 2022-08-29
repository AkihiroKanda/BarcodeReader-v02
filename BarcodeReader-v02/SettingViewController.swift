//
//  SettingViewController.swift
//  BarcodeReader-v02
//
//  Created by 神田章博 on 2022/08/01.
//

import UIKit

class SettingViewController: UIViewController, UITableViewDelegate, UITableViewDataSource{
    let sampleConfig = ["履歴を保存する", "sample1", "sample2"]
    
    
    override func viewDidLoad() {
        super.viewDidLoad()


    }
    
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return sampleConfig.count

    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        // セルを取得する
        let cell: UITableViewCell = tableView.dequeueReusableCell(withIdentifier: "configCell", for: indexPath)
        // セルに表示する値を設定する
        cell.textLabel!.text = sampleConfig[indexPath.row]
        return cell

    }
    
}
