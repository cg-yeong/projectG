//
//  MyMarkers.swift
//  projectG
//
//  Created by root0 on 2022/09/19.
//

import UIKit
import Then
import SnapKit

class MyMarkers: UIView {
    
    private var myCollections = UITableView().then {
        $0.backgroundColor = .black
        $0.register(City.self, forCellReuseIdentifier: City.identifier)
        $0.contentSize.height
    }
    
    private var titleView = UIView().then {
        $0.backgroundColor = .gray
    }
    
    private var titleLabel = UILabel().then {
        $0.text = "내 컬렉션"
        $0.textColor = .white
        $0.font = .systemFont(ofSize: 15, weight: .bold)
    }
    
    private var editBtn = UIButton().then {
        $0.setImage(UIImage(named: ""), for: .normal)
        $0.tintColor = .white
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }
    
    required init?(coder: NSCoder) {
        fatalError()
    }
    
    private func commonInit() {
        [titleView, myCollections].forEach {
            self.addSubview($0)
        }
        
        titleView.snp.remakeConstraints {
            $0.leading.trailing.equalToSuperview()
            $0.top.equalTo(safeAreaLayoutGuide.snp.top)
            $0.height.equalTo(100)
        }
        
        myCollections.snp.remakeConstraints {
            $0.leading.trailing.equalToSuperview()
            $0.bottom.equalTo(safeAreaLayoutGuide.snp.bottom)
            $0.top.equalTo(titleView.snp.bottomMargin)
        }
        
        configureTableView()
    }
    
    private func configureTableView() {
        myCollections.dataSource = self
        myCollections.delegate = self
        
    }
    
}

extension MyMarkers: UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        return Mocks.shared.collections.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if let cell = tableView.dequeueReusableCell(withIdentifier: City.identifier, for: indexPath) as? City {
            cell.setData(Mocks.shared.collections[indexPath.row])
            return cell
        }
        return UITableViewCell()
    }
    
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        
    }
    
    
}
