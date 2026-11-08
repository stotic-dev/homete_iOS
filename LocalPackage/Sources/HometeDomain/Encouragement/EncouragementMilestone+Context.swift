//
//  EncouragementMilestone+Context.swift
//  LocalPackage
//

public extension EncouragementMilestone {

    init(context: EncouragementContext) {
        if context.own.todayCompletedCount == 0 {
            self = .noActivity
        } else if context.today.isAllCompleted {
            self = .allCompleted
        } else {
            self = .inProgress
        }
    }

}
