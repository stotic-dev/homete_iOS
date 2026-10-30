//
//  Exports.swift
//  HometeDomain
//

// UIが使う値型はHometeModelに置いている（doc/adr/0063）。HometeDomainを使う側が
// HometeModelも併せてimportしなくて済むよう、再公開する
@_exported import HometeModel
