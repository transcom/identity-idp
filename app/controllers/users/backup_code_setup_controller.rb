module Users
  class BackupCodeSetupController < ApplicationController
    before_action :authenticate_user!
    before_action :confirm_two_factor_authenticated, if: :two_factor_enabled?

    def index
      generate_codes
      user_session[:codes] = @codes
      result = BackupCodeSetupForm.new(current_user, user_session).submit
      analytics.track_event(Analytics::BACKUP_CODE_SETUP_VISIT, result.to_h)
      mark_user_as_fully_authenticated
    end

    private

    def generate_codes
      @presenter = TwoFactorAuthCode::BackupCodePresenter.new(data: { current_user: current_user },
                                                              view: view_context)
      generator = BackupCodeGenerator.new(@current_user)
      @codes = generator.generate
    end

    def mark_user_as_fully_authenticated
      user_session[TwoFactorAuthentication::NEED_AUTHENTICATION] = false
      user_session[:authn_at] = Time.zone.now
    end

    def two_factor_enabled?
      MfaPolicy.new(current_user).two_factor_enabled?
    end
  end
end