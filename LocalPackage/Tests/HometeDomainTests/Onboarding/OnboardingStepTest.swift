//
//  OnboardingStepTest.swift
//  LocalPackage
//

@testable import HometeDomain
import Testing

struct OnboardingStepTest {

    @Test("匿名でパートナー登録を終えたら、パートナー登録の直後にApple連携を案内する")
    func steps_anonymousRegisteredPartner() {
        // Act

        let actual = OnboardingStep.steps(
            isAnonymous: true,
            shouldGuideNotification: true,
            hasRegisteredPartner: true
        )

        // Assert

        let expected: [OnboardingStep] = [
            .registration,
            .partnerRegistration,
            .accountLink,
            .notificationPermission,
            .premiumIntroduction,
        ]
        #expect(actual == expected)
    }

    @Test("匿名でもパートナー登録を終えるまで（「あとで」を選んだときも）、Apple連携は案内しない")
    func steps_anonymousNotRegisteredPartner() {
        // Act

        let actual = OnboardingStep.steps(
            isAnonymous: true,
            shouldGuideNotification: true,
            hasRegisteredPartner: false
        )

        // Assert

        let expected: [OnboardingStep] = [
            .registration,
            .partnerRegistration,
            .notificationPermission,
            .premiumIntroduction,
        ]
        #expect(actual == expected)
    }

    @Test("Appleでログインして始めた人には、パートナー登録を終えてもApple連携を案内しない")
    func steps_appleRegisteredPartner() {
        // Act

        let actual = OnboardingStep.steps(
            isAnonymous: false,
            shouldGuideNotification: true,
            hasRegisteredPartner: true
        )

        // Assert

        let expected: [OnboardingStep] = [
            .registration,
            .partnerRegistration,
            .notificationPermission,
            .premiumIntroduction,
        ]
        #expect(actual == expected)
    }

    @Test("通知の権限が決定済みなら、通知の案内を除く")
    func steps_notificationDetermined() {
        // Act

        let actual = OnboardingStep.steps(
            isAnonymous: true,
            shouldGuideNotification: false,
            hasRegisteredPartner: true
        )

        // Assert

        let expected: [OnboardingStep] = [
            .registration,
            .partnerRegistration,
            .accountLink,
            .premiumIntroduction,
        ]
        #expect(actual == expected)
    }

}
