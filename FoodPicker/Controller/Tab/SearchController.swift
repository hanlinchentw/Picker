//
//  SearchController.swift
//  FoodPicker
//
//  Created by 陳翰霖 on 2020/7/5.
//  Copyright © 2020 陳翰霖. All rights reserved.
//

import UIKit
import CoreLocation

private let searchHeaderIdentifier = "searchBar"
private let searchShortcutIdentifier = "searchShortcut"

class SearchController: UICollectionViewController {
    //MARK: - Properties
    var restaurants = [Restaurant]()
    private let tableView = UITableView()
    
    private let searchVC = SearchTableViewController(style: .grouped)
    private let resultVC = SearchResultController()
    //MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        configureUI()
        configureCollectionView()
    }
    //MARK: - Helpers
    func configureUI(){
        navigationController?.navigationBar.isHidden = true
        navigationController?.navigationBar.isTranslucent = true
        collectionView.backgroundColor = .backgroundColor
    }
    
    func configureCollectionView(){
        collectionView.register(SearchShortcutSection.self, forCellWithReuseIdentifier: searchShortcutIdentifier)
        collectionView.register(SearchHeader.self, forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: searchHeaderIdentifier)
    }
    func showSearchTable(shouldShow: Bool){
        if shouldShow{
            self.searchVC.view.isHidden = false
            UIView.animate(withDuration: 0.3) {
                self.searchVC.view.alpha = 1
            }
        }else{
            UIView.animate(withDuration: 0.3, animations: {
                self.searchVC.view.alpha = 0
            }) { (_) in
                self.searchVC.view.isHidden = true
            }
        }
    }
    func showResultView(shouldShow: Bool){
        if shouldShow{
            self.resultVC.view.isHidden = false
            UIView.animate(withDuration: 0.2) {
                self.resultVC.view.alpha = 1
            }
        }else{
            UIView.animate(withDuration: 0.2, animations: {
                self.resultVC.view.alpha = 0
            }) { (_) in
                self.resultVC.view.isHidden = true
            }
            
        }
    }
    func shouldCloseKeyboard(should:Bool, term:String?){
        guard let header = collectionView.visibleSupplementaryViews(ofKind: UICollectionView.elementKindSectionHeader)[0] as? SearchHeader else { return }
        if should{
            header.searchBar.text?.removeAll()
            header.searchBar.clearButtonMode = .whileEditing
        }else{
            header.searchBar.text = term
            header.searchBar.clearButtonMode = .always
        }
    }
    //MARK: - API
    func fetchRestautantsByterms(term: String){
        guard let location = LocationHandler.shared.locationManager.location?.coordinate else { return }
        NetworkService.shared.fetchRestaurantsByTerm(lat: location.latitude, lon: location.longitude,terms: term) { (restaurants) in
            if let restaurants = restaurants {
                self.resultVC.searchResult = restaurants
                self.resultVC.statLabel.text = "\(restaurants.count) results for ' \(term) ' "
            }
        }
    }
    func addHistoricalRecordByTerm(term:String){
        RestaurantService.shared.addHistoricalRecordbyTerm(term: term)
    }
}
//MARK: - UICollectionviewDelegate / Datasoruce
extension SearchController {
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return 3
    }
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: searchShortcutIdentifier, for: indexPath)
        as! SearchShortcutSection
        let title = ["Recent Searches","Top Searches","Top Categories"]
        cell.isKeywordSection = indexPath.row == 2 ?  false : true
        cell.titleLabel.text = title[indexPath.row]
        return cell
    }
    override func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        let header = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: searchHeaderIdentifier, for: indexPath) as! SearchHeader
        header.delegate = self
        return header
    }
}
//MARK: - UICollectionViewDelegateFlowLayout
extension SearchController: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        
        let height : CGFloat = indexPath.row == 2 ?  CGFloat(categoryPreload.count/3 * 116) - 50 : 56
        return CGSize(width: view.frame.width, height: height)
    }
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        return CGSize(width: view.frame.width, height: 40 + 24*2)
    }
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 24
    }
}
//MARK: - SearchHeaderDelegate
extension SearchController: SearchHeaderDelegate{
    func didTapSearchHeader() {
        addChild(searchVC)
        searchVC.delegate = self
        view.addSubview(searchVC.view)
        searchVC.view.alpha = 0
        searchVC.view.frame = self.view.frame
        
        self.showSearchTable(shouldShow: true)
        self.showResultView(shouldShow: false)
    }
    func didClearSearchHeader() {
        self.showResultView(shouldShow: false)
        self.showSearchTable(shouldShow: false)
        shouldCloseKeyboard(should: true, term: nil)
        self.resultVC.removeFromParent()
    }
}
//MARK: - SearchTableViewControllerDelegate
extension SearchController: SearchTableViewControllerDelegate{
    func didTapBackButton() {
        self.showSearchTable(shouldShow: false)
        shouldCloseKeyboard(should: true, term: nil)
    }
    
    func didSearchbyTerm(term: String) {
        self.fetchRestautantsByterms(term: term)
        self.addChild(self.resultVC)
        self.view.addSubview(self.resultVC.view)
        self.resultVC.view.alpha = 0
        self.resultVC.view.frame = self.view.frame
        self.resultVC.view.frame.origin.y =
            (self.collectionView.cellForItem(at: IndexPath(row: 0, section: 0))?.frame.origin.y)! + 20 + 16
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 1.5) {
            self.shouldCloseKeyboard(should: false, term: term)
            self.showResultView(shouldShow: true)
            self.showSearchTable(shouldShow: false)
        }
        self.addHistoricalRecordByTerm(term: term)
    }
}
//MARK: - SearchHeader
protocol SearchHeaderDelegate: class {
    func didTapSearchHeader()
    func didClearSearchHeader()
}
class SearchHeader: UICollectionReusableView {
    //MARK: - Properties
    lazy var searchBar : UITextField = {
        let bar = UITextField().createSearchBar(withPlaceholder: "Search for food or categories")
        let tap = UITapGestureRecognizer(target: self, action: #selector(handleTapSearchBar))
        bar.addGestureRecognizer(tap)
        bar.isUserInteractionEnabled = true
        bar.clearButtonMode = .whileEditing
        return bar
    }()
    weak var delegate : SearchHeaderDelegate?
    //MARK: - Lifecycle
    override init(frame: CGRect) {
        super.init(frame:frame)
        searchBar.delegate = self
        addSubview(searchBar)
        searchBar.anchor(left: leftAnchor, right: rightAnchor,
                         paddingLeft: 16, paddingRight: 16, height: 40)
        searchBar.centerY(inView: self)
    }
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    //MARK: - Selectors
    @objc func handleTapSearchBar(){
        delegate?.didTapSearchHeader()
    }
}
extension SearchHeader: UITextFieldDelegate{
    func textFieldShouldClear(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        delegate?.didClearSearchHeader()
        return false
    }
}
