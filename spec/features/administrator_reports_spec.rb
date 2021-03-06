# frozen_string_literal: true

require 'rails_helper'

RSpec.feature 'Administrator Reports' do
  given(:user) { create :subject }

  describe 'when subject is administrator' do
    %w[identity_providers
       service_providers organizations
       rapid_connect_services services].each do |identifier|
      %w[monthly quarterly yearly].each do |interval|
        given!("auto_report_#{identifier}_#{interval}".to_sym) do
          create :automated_report,
                 interval: interval,
                 target: identifier,
                 report_class: 'SubscriberRegistrationsReport'
        end
      end
    end

    background do
      entitlements = ['urn:mace:aaf.edu.au:ide:internal:aaf-admin']
      admins = Rails.application.config.reporting_service.admins
      admins[user.shared_token.to_sym] = entitlements

      attrs = create(:aaf_attributes, :from_subject, subject: user)
      RapidRack::TestAuthenticator.jwt = create(:jwt, aaf_attributes: attrs)

      visit '/auth/login'
      click_button 'Login'
      visit '/admin_reports'
    end

    scenario 'viewing the Administrator Reports Dashboard' do
      expect(current_path).to eq('/admin_reports')
      expect(page).to have_css('.list-group')
    end

    context 'Subscriber Registrations' do
      given(:identifiers) do
        %w[organizations identity_providers service_providers
           rapid_connect_services services]
      end

      scenario 'viewing Report' do
        message1 = 'You have successfully subscribed to this report'
        message2 = 'You have already subscribed to this report'

        click_link 'Subscriber Registrations Report'

        %w[Monthly Quarterly Yearly].each do |interval|
          identifiers.each do |identifier|
            select(identifier.titleize, from: 'Subscriber Identifiers')
            click_button('Generate')
            expect(page).to have_css('table.subscriber-registrations')
            click_button('Subscribe')
            click_link(interval)
            expect(page).to have_selector('p', text: message1)

            select(identifier.titleize, from: 'Subscriber Identifiers')
            click_button('Generate')
            expect(page).to have_css('table.subscriber-registrations')
            click_button('Subscribe')
            click_link(interval)
            expect(page).to have_selector('p', text: message2)

            expect(current_path)
              .to eq('/admin_reports/subscriber_registrations_report')
          end
        end
      end
    end

    context 'Federation Growth Report' do
      scenario 'viewing Report' do
        click_link 'Federation Growth Report'

        page.execute_script("$('input').removeAttr('readonly')")

        fill_in 'start', with: Time.now.utc.beginning_of_month - 1.month
        fill_in 'end', with: Time.now.utc.beginning_of_month

        # HACK: Works around an overlapping element that affects this test.
        find('button', text: 'Generate').trigger('click')

        expect(current_path)
          .to eq('/admin_reports/federation_growth_report')
        expect(page).to have_css('svg.federation-growth')
      end
    end

    shared_examples 'Daily Demand Report' do
      scenario 'viewing Report' do
        click_link 'Daily Demand Report'

        page.execute_script("$('input').removeAttr('readonly')")

        fill_in 'start', with: Time.now.utc.beginning_of_month - 1.month
        fill_in 'end', with: Time.now.utc.beginning_of_month
        select data_source_name, from: 'source'

        click_button('Generate')

        expect(current_path)
          .to eq('/admin_reports/daily_demand_report')
        expect(page).to have_css('svg.daily-demand')
        expect(page).to have_content("(#{data_source_name})")
      end
    end

    shared_examples 'Federated Sessions Report' do
      scenario 'viewing Report' do
        click_link 'Federated Sessions Report'

        page.execute_script("$('input').removeAttr('readonly')")

        fill_in 'start', with: Time.now.utc.beginning_of_month - 1.month
        fill_in 'end', with: Time.now.utc.beginning_of_month
        select data_source_name, from: 'source'

        click_button('Generate')

        expect(current_path)
          .to eq('/admin_reports/federated_sessions_report')
        expect(page).to have_css('svg.federated-sessions')
        expect(page).to have_content("(#{data_source_name})")
      end
    end

    shared_examples 'Identity Provider Utilization Report' do
      scenario 'viewing Report' do
        click_link 'Identity Provider Utilization Report'

        page.execute_script("$('input').removeAttr('readonly')")

        fill_in 'start', with: Time.now.utc.beginning_of_month - 1.month
        fill_in 'end', with: Time.now.utc.beginning_of_month
        select data_source_name, from: 'source'

        click_button('Generate')

        expect(current_path)
          .to eq('/admin_reports/identity_provider_utilization_report')
        expect(page).to have_css('table.identity-provider-utilization')
        # Tabular reports do not render report title - see #178
        # So instead just confirm the report-data JSON contains the title.
        report_data = page.evaluate_script(
          'document.getElementsByClassName("report-data")[0].innerHTML'
        )
        expect(report_data).to have_text("(#{data_source_name})")
      end
    end

    shared_examples 'Service Provider Utilization Report' do
      scenario 'viewing Report' do
        click_link 'Service Provider Utilization Report'

        page.execute_script("$('input').removeAttr('readonly')")

        fill_in 'start', with: Time.now.utc.beginning_of_month - 1.month
        fill_in 'end', with: Time.now.utc.beginning_of_month
        select data_source_name, from: 'source'

        click_button('Generate')

        expect(current_path)
          .to eq('/admin_reports/service_provider_utilization_report')
        expect(page).to have_css('table.service-provider-utilization')
        # Tabular reports do not render report title - see #178
        # So instead just confirm the report-data JSON contains the title.
        report_data = page.evaluate_script(
          'document.getElementsByClassName("report-data")[0].innerHTML'
        )
        expect(report_data).to have_text("(#{data_source_name})")
      end
    end

    context 'selecting DS session data source' do
      let(:data_source_name) { 'Discovery Service' }

      it_behaves_like 'Daily Demand Report'
      it_behaves_like 'Federated Sessions Report'
      it_behaves_like 'Identity Provider Utilization Report'
      it_behaves_like 'Service Provider Utilization Report'
    end

    context 'selecting IdP session data source' do
      let(:data_source_name) { 'IdP Event Log' }

      it_behaves_like 'Daily Demand Report'
      it_behaves_like 'Federated Sessions Report'
      it_behaves_like 'Identity Provider Utilization Report'
      it_behaves_like 'Service Provider Utilization Report'
    end
  end
end
