class SafeExecutableValidator < ActiveModel::EachValidator
    # https://docs.guardrails.io/docs/vulnerabilities/ruby/insecure_use_of_dangerous_function
    BLACKLISTED_KEYWORDS = [
        'exit',
        'exec',
        'syscall',
        'system',
        'eval',
        'render',
        'call',
        'send',
        'constantize',
        'update_all',
        'destroy_all',
        'switch',
        'global_admin',
        'Subdomain',
        'Tenant',
        'Apartment',
        'ActiveRecord::Base',
        'find_by_sql',
        'select_all',
        'Rails'
    ] + User::PRIVATE_ATTRIBUTES.map(&:to_s) + User::FULL_PERMISSIONS.keys.map(&:to_s)
     
    # BLACKLISTED_KEYWORDS are usually attached to one of these delimiters
    # eg: exit(), .constantize, Subdomain.destroy_all, can_manage_users:
    SPLIT_DELIMITERS = ['(', ')', /\s/, '.', /\n/, /(?<!\:)\:(?!\:)/, '#{', '}', '=>', '"', '\'']

    def validate_each(record,attribute,value)
        keywords = value.to_s.split(Regexp.union(SPLIT_DELIMITERS)).reject(&:blank?)
        blacklisted_keywords_in_attribute = keywords & BLACKLISTED_KEYWORDS
        unless blacklisted_keywords_in_attribute.empty?
            record.errors.add(attribute, "contains disallowed keyword: #{blacklisted_keywords_in_attribute.to_s}. Please refactor #{attribute} accordingly")
        end
    end
end