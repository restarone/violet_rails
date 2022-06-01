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
        'can_manage_users',
        'global_admin',
        'Subdomain',
        'Tenant',
        'Apartment',
    ] + User::PRIVATE_ATTRIBUTES.map(&:to_s)

    # BLACKLISTED_KEYWORDS are usually attached to one of these delimiters
    # eg: exit(), .constantize, Subdomain.destroy_all, can_manage_users:
    SPLIT_DELIMITERS = ['(', ')', /\s/, '.', /\n/, ':']

    def validate_each(record,attribute,value)
        keywords = value.split(Regexp.union(SPLIT_DELIMITERS)).reject(&:blank?)
        blacklisted_keywords_in_attribute = keywords & BLACKLISTED_KEYWORDS
        unless blacklisted_keywords_in_attribute.empty?
            record.errors.add(attribute, "contains blacklisted keyword: #{blacklisted_keywords_in_attribute.to_s}. Please refactor #{attribute} accordingly")
        end
    end
end