class Profile < ActiveRecord::Base
  validates :linkedin_id, uniqueness: true
  belongs_to :campaings

  def self.search(campaign_id, search)
    if search
      where(campaign_id: campaign_id).where(
        ['name LIKE ?
         OR title LIKE ?
         OR company LIKE ?
         OR email LIKE ?',
         "%#{search}%",
         "%#{search}%",
         "%#{search}%",
         "%#{search}%"]
      ).order("company, lower(name)")
    else
      where(campaign_id: campaign_id).all.order("company, lower(name)")
    end
  end

  def self.to_pipedrive
    headers = ["Email", "Firstname", "Lastname", "Organization",
      "Title", "Gender", "Company Gender", "Source", "Vertical",
      "linkedin_url", "Website"]

    attributes = %w{email first_name last_name company
      title gender company_gender source vertical
      linkedin_url website}

    CSV.generate(headers: true, force_quotes: true) do |csv|
      csv << headers

      all.each do |profile|
        csv << attributes.map{ |attr| profile.send(attr) }
      end
    end
  end

  def self.to_replyapp
    headers = ["Email", "First Name", "Last Name", "Company",
      "Title", "Person (a/o)", "Company (a/o)" ]

    attributes = %w{email first_name last_name company
      title gender_oa company_gender_oa }

    CSV.generate(headers: true, force_quotes: true) do |csv|
      csv << headers

      all.each do |profile|
        csv << attributes.map{ |attr| profile.send(attr) }
      end
    end
  end

  def source
    "Cold Call 2.0"
  end

  def vertical
    ""
  end

  def gender_oa
    g = gender.downcase
    return g == "male" ? "o" : g == "female" ? "a" : ""
  end

  def company_gender_oa
    g = company_gender.downcase
    return g == "male" ? "o" : g == "female" ? "a" : ""
  end
end
