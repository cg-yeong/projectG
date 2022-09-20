//
//  City.swift
//  projectG
//
//  Created by root0 on 2022/09/19.
//

import UIKit
import Then
import SnapKit

class City: UITableViewCell {
    static let identifier = "City"
    private var container = UIView().then {
        $0.backgroundColor = .clear
    }
    
    private var cityName = UILabel().then {
        $0.text = ""
        $0.font = .systemFont(ofSize: 16, weight: .semibold)
    }
    
    private var timeDifference = UILabel().then {
        $0.text = ""
        $0.font = .systemFont(ofSize: 12, weight: .regular)
    }
    
    
    private var cityTime = UIStackView().then {
        $0.axis = .vertical
        $0.alignment = .center
        $0.distribution = .fill
        $0.spacing = 4
    }
    
    private var ampm = UILabel().then {
        $0.text = ""
        $0.font = .systemFont(ofSize: 12, weight: .semibold)
    }
    
    private var timeClock = UILabel().then {
        $0.text = ":"
        $0.font = .systemFont(ofSize: 24, weight: .semibold)
    }
    
    private var whatTime = UIStackView().then {
        $0.axis = .horizontal
        $0.alignment = .bottom
        $0.distribution = .fill
        $0.spacing = 2
    }
    
    private var weatherImage = UIImageView().then {
        $0.image = UIImage(named: "")
        $0.backgroundColor = .clear
    }
    
    private var temperature = UILabel().then {
        /// ° ℃ ℉
        $0.text = ""
        $0.font = .systemFont(ofSize: 9, weight: .regular)
    }
    
    private var weather = UIStackView().then {
        $0.axis = .vertical
        $0.alignment = .center
        $0.distribution = .fill
        $0.spacing = 4
    }
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        addingView()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func addingView() {
        contentView.addSubview(container)
        [cityTime, weather, whatTime].forEach {
            container.addSubview($0)
        }
        
        [cityName, timeDifference].forEach {
            cityTime.addArrangedSubview($0)
        }
        [ampm, timeClock].forEach {
            whatTime.addArrangedSubview($0)
        }
        [weatherImage, temperature].forEach {
            weather.addArrangedSubview($0)
        }
        container.snp.remakeConstraints {
            $0.edges.equalToSuperview()
        }
        
        cityTime.snp.remakeConstraints {
            $0.centerY.equalToSuperview()
            $0.leading.equalTo(container.snp.leadingMargin)
//            $0.trailing.greaterThanOrEqualTo(whatTime.snp.leading).offset(0)
        }
        
        weather.snp.remakeConstraints {
            $0.centerY.equalToSuperview()
            $0.trailing.equalTo(container.snp.trailingMargin)
        }
        
        whatTime.snp.remakeConstraints {
            $0.centerY.equalToSuperview()
            $0.trailing.equalTo(weather.snp.leadingMargin)
        }
    }
    
    func setData(_ data: MockCollection) {
        cityName.text = data.city
        timeDifference.text = data.time
        timeClock.text = data.clock
        ampm.text = data.noon
        weatherImage.image = UIImage(named: data.weather)
        temperature.text = data.temper
        
    }
}
