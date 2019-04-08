class TwoFactorOptionsPresenter
  include ActionView::Helpers::TranslationHelper

  attr_reader :current_user, :service_provider

  def initialize(current_user, sp)
    @current_user = current_user
    @service_provider = sp
  end

  def title
    t('titles.two_factor_setup')
  end

  def heading
    if FeatureManagement.force_multiple_auth_methods? &&
       MfaContext.new(current_user).enabled_mfa_methods_count == 1
      t('headings.account_recovery_setup.secondary_method')
    else
      t('two_factor_authentication.two_factor_choice')
    end
  end

  def info
    if FeatureManagement.force_multiple_auth_methods? &&
       MfaContext.new(current_user).enabled_mfa_methods_count == 1
      t('instructions.account_recovery_setup.secondary_method_next_step')
    else
      t('two_factor_authentication.two_factor_choice_intro')
    end
  end

  def label
    if FeatureManagement.force_multiple_auth_methods? &&
      MfaContext.new(current_user).enabled_mfa_methods_count == 1
      t('forms.two_factor_choice.secondary_method') + ':'
    else
      t('forms.two_factor_choice.legend') + ':'
    end
  end

  def options
    phone_options + totp_option + webauthn_option + piv_cac_option + backup_code_option
  end

  private

  def phone_options
    if TwoFactorAuthentication::PhonePolicy.new(current_user).available?
      [
        TwoFactorAuthentication::SmsSelectionPresenter.new,
        TwoFactorAuthentication::VoiceSelectionPresenter.new,
      ]
    else
      []
    end
  end

  def webauthn_option
    if TwoFactorAuthentication::WebauthnPolicy.new(current_user).available?
      [TwoFactorAuthentication::WebauthnSelectionPresenter.new]
    else
      []
    end
  end

  def totp_option
    if TwoFactorAuthentication::AuthAppPolicy.new(current_user).available? &&
       !TwoFactorAuthentication::AuthAppPolicy.new(current_user).configured?
      [TwoFactorAuthentication::AuthAppSelectionPresenter.new]
    else
      []
    end
  end

  def piv_cac_option
    policy = TwoFactorAuthentication::PivCacPolicy.new(current_user)
    return [] if policy.enabled?
    return [] unless policy.available? ||
                     service_provider&.piv_cac_available?(current_user) ||
                     policy.configured?
    [TwoFactorAuthentication::PivCacSelectionPresenter.new]
  end

  # :reek:FeatureEnvy
  def backup_code_option
    policy = TwoFactorAuthentication::BackupCodePolicy.new(current_user)
    return [TwoFactorAuthentication::BackupCodeSelectionPresenter.new] if policy.available? &&
                                                                          !policy.enabled?
    []
  end
end
