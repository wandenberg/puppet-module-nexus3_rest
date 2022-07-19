require 'spec_helper'

describe Puppet::Type.type(:nexus3_task) do
  let(:required_values) do
    {
      name: 'default',
      frequency: 'manual',
      type: 'blobstore.compact',
    }
  end

  describe 'by default' do
    let(:instance) { described_class.new(required_values) }

    it { expect(instance[:enabled]).to eq(:true) }
    it { expect(instance[:alert_email]).to eq('') }
  end

  it 'validate type' do
    expect {
      described_class.new(required_values.merge(type: 'invalid'))
    }.to raise_error(Puppet::ResourceError, %r{Parameter type failed})
  end

  describe 'frequency' do
    it 'validate' do
      expect {
        described_class.new(required_values.merge(frequency: 'invalid'))
      }.to raise_error(Puppet::ResourceError, %r{Parameter frequency failed})
    end

    specify 'should accept a valid type' do
      expect { described_class.new(required_values.merge(frequency: 'manual')) }.not_to raise_error
    end

    describe 'for manual' do
      specify 'should not accept cron_expression field' do
        expect {
          described_class.new(required_values.merge(frequency: 'manual', cron_expression: '* * * * *'))
        }.to raise_error(ArgumentError, %r{cron_expression not allowed when frequency is set to 'manual'})
      end

      specify 'should not accept recurring_day field' do
        expect {
          described_class.new(required_values.merge(frequency: 'manual', recurring_day: ['sunday']))
        }.to raise_error(ArgumentError, %r{recurring_day not allowed when frequency is set to 'manual'})
      end

      specify 'should not accept start_date field' do
        expect {
          described_class.new(required_values.merge(frequency: 'manual', start_date: '2017-12-21'))
        }.to raise_error(ArgumentError, %r{start_date not allowed when frequency is set to 'manual'})
      end

      specify 'should not accept start_time field' do
        expect {
          described_class.new(required_values.merge(frequency: 'manual', start_time: '23:59'))
        }.to raise_error(ArgumentError, %r{start_time not allowed when frequency is set to 'manual'})
      end
    end

    %w[once hourly daily].each do |frequency|
      describe "for #{frequency}" do
        specify 'should not accept cron_expression field' do
          expect {
            described_class.new(required_values.merge(frequency: frequency, cron_expression: '* * * * *'))
          }.to raise_error(ArgumentError, %r{cron_expression not allowed when frequency is set to '#{frequency}'})
        end

        specify 'should not accept recurring_day field' do
          expect {
            described_class.new(required_values.merge(frequency: frequency, recurring_day: ['sunday']))
          }.to raise_error(ArgumentError, %r{recurring_day not allowed when frequency is set to '#{frequency}'})
        end

        specify 'should accept start_date and start_time field together' do
          expect {
            described_class.new(required_values.merge(frequency: frequency, start_date: '2017-12-21', start_time: '23:59'))
          }.not_to raise_error
        end
      end
    end

    describe 'for weekly' do
      specify 'should not accept cron_expression field' do
        expect {
          described_class.new(required_values.merge(frequency: 'weekly', cron_expression: '* * * * *'))
        }.to raise_error(ArgumentError, %r{cron_expression not allowed when frequency is set to 'weekly'})
      end

      specify 'should accept start_date, start_time and recurring_day field together' do
        expect {
          described_class.new(required_values.merge(frequency: 'weekly', start_date: '2017-12-21', start_time: '23:59', recurring_day: %w[monday saturday]))
        }.not_to raise_error
      end
    end

    describe 'for monthly' do
      specify 'should not accept cron_expression field' do
        expect {
          described_class.new(required_values.merge(frequency: 'monthly', cron_expression: '* * * * *'))
        }.to raise_error(ArgumentError, %r{cron_expression not allowed when frequency is set to 'monthly'})
      end

      specify 'should accept start_date, start_time and recurring_day field together' do
        expect {
          described_class.new(required_values.merge(frequency: 'monthly', start_date: '2017-12-21', start_time: '23:59', recurring_day: %w[15 30 last]))
        }.not_to raise_error
      end
    end

    describe 'for advanced' do
      specify 'should not accept recurring_day field' do
        expect {
          described_class.new(required_values.merge(frequency: 'advanced', recurring_day: ['sunday']))
        }.to raise_error(ArgumentError, %r{recurring_day not allowed when frequency is set to 'advanced'})
      end

      specify 'should not accept start_date field' do
        expect {
          described_class.new(required_values.merge(frequency: 'advanced', start_date: '2017-12-21'))
        }.to raise_error(ArgumentError, %r{start_date not allowed when frequency is set to 'advanced'})
      end

      specify 'should not accept start_time field' do
        expect {
          described_class.new(required_values.merge(frequency: 'advanced', start_time: '23:59'))
        }.to raise_error(ArgumentError, %r{start_time not allowed when frequency is set to 'advanced'})
      end

      specify 'should accept a cron_expression' do
        expect {
          described_class.new(required_values.merge(frequency: 'advanced', cron_expression: '* * * * * *'))
        }.not_to raise_error
      end

      specify 'should accept an empty cron_expression' do
        expect {
          described_class.new(required_values.merge(frequency: 'advanced', cron_expression: ''))
        }.to raise_error(ArgumentError, %r{cron_expression must not be empty})
      end
    end
  end

  describe 'start_date' do
    specify 'should not accept empty string' do
      expect {
        described_class.new(required_values.merge(frequency: 'once', start_date: ''))
      }.to raise_error(ArgumentError, %r{Setting frequency to 'once' requires start_date and start_time to be set as well})
    end

    specify 'should not accept a value not on the format YYYY-MM-DD' do
      expect {
        described_class.new(required_values.merge(frequency: 'once', start_time: '00:00', start_date: 'date2017-12-21'))
      }.to raise_error(Puppet::ResourceError, %r{Parameter start_date failed})
    end

    specify 'should accept a value on the format YYYY-MM-DD' do
      expect {
        described_class.new(required_values.merge(frequency: 'once', start_time: '00:00', start_date: '2017-12-21'))
      }.not_to raise_error
    end
  end

  describe 'start_time' do
    specify 'should not accept empty string' do
      expect {
        described_class.new(required_values.merge(frequency: 'once', start_date: '2017-12-21', start_time: ''))
      }.to raise_error(ArgumentError, %r{Setting frequency to 'once' requires start_time to be set as well})
    end

    specify 'should not accept a value not on the format HH:MM' do
      expect {
        described_class.new(required_values.merge(frequency: 'once', start_date: '2017-12-21', start_time: '23:59:00'))
      }.to raise_error(Puppet::ResourceError, %r{Parameter start_time failed})
    end

    specify 'should accept a value on the format HH:MM' do
      expect {
        described_class.new(required_values.merge(frequency: 'once', start_date: '2017-12-21', start_time: '23:59'))
      }.not_to raise_error
    end
  end

  describe 'recurring_day' do
    describe 'for weekly frequency' do
      specify 'should not accept empty string' do
        expect {
          described_class.new(required_values.merge(frequency: 'weekly', start_date: '2017-12-21', start_time: '23:59', recurring_day: ''))
        }.to raise_error(ArgumentError, %r{Setting frequency to 'weekly' requires recurring_day to be set as well})
      end

      specify 'should not accept an invalid value' do
        expect {
          described_class.new(required_values.merge(frequency: 'weekly', start_date: '2017-12-21', start_time: '23:59', recurring_day: 'invalid'))
        }.to raise_error(ArgumentError, %r{Multiple recurring days must be provided as an array.})
      end

      specify 'should not accept numbers' do
        expect {
          described_class.new(required_values.merge(frequency: 'weekly', start_date: '2017-12-21', start_time: '23:59', recurring_day: %w[1 5]))
        }.to raise_error(ArgumentError, %r{Recurring day must be one of \[monday, tuesday, wednesday, thursday, friday, saturday, sunday\]})
      end

      specify 'should not accept a string list' do
        expect {
          described_class.new(required_values.merge(frequency: 'weekly', start_date: '2017-12-21', start_time: '23:59', recurring_day: 'tuesday,friday'))
        }.to raise_error(ArgumentError, %r{Multiple recurring days must be provided as an array.})
      end

      specify 'should accept a value on the set monday, tuesday, wednesday, thursday, friday, saturday, sunday' do
        expect {
          described_class.new(required_values.merge(frequency: 'weekly', start_date: '2017-12-21', start_time: '23:59', recurring_day: %w[tuesday friday]))
        }.not_to raise_error
      end
    end

    describe 'for monthly frequency' do
      specify 'should not accept empty string' do
        expect {
          described_class.new(required_values.merge(frequency: 'monthly', start_date: '2017-12-21', start_time: '23:59', recurring_day: ''))
        }.to raise_error(ArgumentError, %r{Setting frequency to 'monthly' requires recurring_day to be set as well})
      end

      specify 'should not accept an invalid value' do
        expect {
          described_class.new(required_values.merge(frequency: 'monthly', start_date: '2017-12-21', start_time: '23:59', recurring_day: 'invalid'))
        }.to raise_error(ArgumentError, %r{Multiple recurring days must be provided as an array.})
      end

      specify 'should not accept numbers' do
        expect {
          described_class.new(required_values.merge(frequency: 'monthly', start_date: '2017-12-21', start_time: '23:59', recurring_day: %w[tuesday friday]))
        }.to raise_error(ArgumentError, %r{Recurring day must be one of \[1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, last\]})
      end

      specify 'should not accept a string list' do
        expect {
          described_class.new(required_values.merge(frequency: 'monthly', start_date: '2017-12-21', start_time: '23:59', recurring_day: '1,5,last'))
        }.to raise_error(ArgumentError, %r{Multiple recurring days must be provided as an array.})
      end

      specify 'should accept a value on the set 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, last' do
        expect {
          described_class.new(required_values.merge(frequency: 'monthly', start_date: '2017-12-21', start_time: '23:59', recurring_day: %w[1 5 last]))
        }.not_to raise_error
      end

      specify 'should accept only last as a value' do
        expect {
          described_class.new(required_values.merge(frequency: 'monthly', start_date: '2017-12-21', start_time: '23:59', recurring_day: ['last']))
        }.not_to raise_error
      end
    end
  end

  describe 'enabled' do
    specify 'should default to false' do
      expect(described_class.new(required_values)[:enabled]).to be :true
    end

    specify 'should accept :true' do
      expect { described_class.new(required_values.merge(enabled: :true)) }.not_to raise_error
      expect(described_class.new(required_values.merge(enabled: :true))[:enabled]).to be :true
    end

    specify 'should accept "true' do
      expect { described_class.new(required_values.merge(enabled: 'true')) }.not_to raise_error
      expect(described_class.new(required_values.merge(enabled: 'true'))[:enabled]).to be :true
    end

    specify 'should accept :false' do
      expect { described_class.new(required_values.merge(enabled: :false)) }.not_to raise_error
      expect(described_class.new(required_values.merge(enabled: :false))[:enabled]).to be :false
    end

    specify 'should accept "false"' do
      expect { described_class.new(required_values.merge(enabled: 'false')) }.not_to raise_error
      expect(described_class.new(required_values.merge(enabled: 'false'))[:enabled]).to be :false
    end
  end

  describe 'type' do
    specify 'should accept a valid type' do
      expect { described_class.new(required_values.merge(type: 'script')) }.not_to raise_error
    end

    specify 'should not have default value for type' do
      expect {
        required_values.delete(:type)
        described_class.new(required_values)
      }.to raise_error(ArgumentError, %r{type must not be empty})
    end

    specify 'should not accept empty string' do
      expect {
        described_class.new(required_values.merge(type: ''))
      }.to raise_error(ArgumentError, %r{type must not be empty})
    end
  end

  describe 'alert_email' do
    specify 'should accept valid email address' do
      expect { described_class.new(required_values.merge(alert_email: 'jdoe@example.com')) }.not_to raise_error
    end

    specify 'should not accept invalid email address' do
      expect {
        described_class.new(required_values.merge(alert_email: 'invalid'))
      }.to raise_error(Puppet::ResourceError, %r{Parameter alert_email failed})
    end
  end

  describe 'when removing' do
    it { expect { described_class.new(name: 'any', ensure: :absent) }.not_to raise_error }
  end
end
