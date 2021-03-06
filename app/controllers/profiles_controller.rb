class ProfilesController < ApplicationController
  before_action :set_profile, only: [:show, :edit, :update, :destroy]

  # GET /profiles
  # GET /profiles.json
  def index
    @campaign = Campaign.find(params[:campaign_id])
    @profiles = Profile.search(params[:campaign_id], params[:search])
  end

  def csv_pipedrive
    @campaign = Campaign.find(params[:campaign_id])
    @profiles = Profile.search(params[:campaign_id], params[:search])

    respond_to do |format|
      format.csv { send_data @profiles.to_pipedrive, filename: "Profiles-Pipedrive-#{@campaign.id}-#{Date.today}.csv" }
    end
  end

  def csv_replyapp
    @campaign = Campaign.find(params[:campaign_id])
    @profiles = Profile.search(params[:campaign_id], params[:search])

    respond_to do |format|
      format.csv { send_data @profiles.to_replyapp, filename: "Profiles-ReplyApp-#{@campaign.id}-#{Date.today}.csv" }
    end
  end

  # GET /profiles/1
  # GET /profiles/1.json
  def show
  end

  # GET /profiles/new
  def new
    @profile = Profile.new
  end

  # GET /profiles/1/edit
  def edit
    @next = Profile.where(campaign_id: params[:campaign_id])
      .all.order("company, lower(name)").offset(params[:offset].to_i).first
    if @profile.website.present?
      @domain = Domainatrix.parse(@profile.website.downcase).domain_with_public_suffix
      @emails = Email.where(domain: @domain).pluck(:email)
      if @emails.any?
        @emails.unshift("-- Emails from this domain --")
      end
      if @domain
        @email_options = [
          "-- Ready formats --",
          I18n.transliterate(@profile.first_name + "." + @profile.last_name + "@" + @domain).downcase,
          I18n.transliterate(@profile.first_name[0] + @profile.last_name + "@" + @domain).downcase,
          I18n.transliterate(@profile.first_name[0] + "." + @profile.last_name + "@" + @domain).downcase,
          I18n.transliterate(@profile.first_name + @profile.last_name[0] + "@" + @domain).downcase,
          I18n.transliterate(@profile.first_name + "@" + @domain).downcase,
          I18n.transliterate(@profile.last_name + "@" + @domain).downcase
        ]
      end
    end
  end

  # POST /profiles
  # POST /profiles.json
  def create
    @profile = Profile.new(profile_params)

    respond_to do |format|
      if @profile.save
        format.html { redirect_to campaign_profile_path(@campaign, @profile), notice: 'Profile was successfully created.' }
        format.json { head :ok}
      else
        format.html { render :new }
        # do not return error to API
        # format.json { render json: @profile.errors, status: :unprocessable_entity }
        format.json { head :ok}
      end
    end
  end

  # PATCH/PUT /profiles/1
  # PATCH/PUT /profiles/1.json
  def update
    respond_to do |format|
      if @profile.update(profile_params)
        format.html { redirect_to edit_campaign_profile_path(@campaign, @profile, offset: params[:offset]), notice: 'Profile was successfully updated.' }
        format.json { head :ok }
      else
        format.html { render :edit }
        format.json { head :unprocessable_entity }
      end
    end
  end

  # DELETE /profiles/1
  # DELETE /profiles/1.json
  def destroy
    @profile.destroy
    respond_to do |format|
      format.html { redirect_to campaign_profiles_path(@campaign), notice: 'Profile was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  def destroy_multiple
    @campaign = Campaign.find(params[:campaign_id])
    Profile.destroy(params[:campaign_profiles])

    respond_to do |format|
      format.html { redirect_to campaign_profiles_path(@campaign), notice: 'Profiles was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  def import_domains
    @campaign = Campaign.find(params[:id])
    url = "#{ENV['CLOUDANT']}/sitemap-data-linkedin-company-url-campaign-#{params[:id]}/_all_docs?include_docs=true"
    resource = RestClient::Resource.new(url)
    @data = resource.get()
    @json = JSON.parse(@data)
    i = 0

    @json['rows'].each do |j|
      company_id = j['doc']['company-id-href'].split('pivotId=')[1].split('&')[0],
      website = j['doc']['url']

      if website.present?
        domain = Domainatrix.parse(website.downcase).domain_with_public_suffix
        @profiles = Profile.where(linkedin_company_id: company_id)
        @profiles.update_all(website: website, domain: domain)
        i += 1
      end
    end

    redirect_to @campaign, notice: "Imported #{i} domains"
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_profile
      @profile = Profile.find(params[:id])
      @campaign = Campaign.find(params[:campaign_id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def profile_params
      params.require(:profile).permit(:name, :first_name, :last_name, :company, :title, :address_full, :address_city, :address_country, :image, :linkedin_id, :linkedin_url, :linkedin_company_id, :website, :domain, :gender, :company_gender, :source, :vertical, :email, :campaign_id, :offset_hidden)
    end
end
