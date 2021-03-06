namespace :deploy do
  desc 'prepare git tree so we can tag on successful deployment'
  before :deploy, :prepare_tree do
    run_locally do
      if ENV['NO_DEPLOYTAGS'] || fetch(:no_deploytags, false)
        info "[deploytags] Skipping deploytags"
      else
        branch = fetch(:branch, false)
        stage = fetch(:stage, false)
        tag_name = CapistranoDeploytags::Helper.git_tag_for(fetch(:stage)

        unless branch && stage
          error 'capistrano-deploytags requires that :branch and :stage be defined'
          raise 'define :branch and :stage'
        end

        strategy.git "fetch #{fetch(:git_remote, 'origin')}"

        diff_output = capture :git, "diff #{branch} --shortstat"

        unless diff_output.empty?
          error "Whoa there, partner. Dirty trees can't deploy. Git yerself clean first"
          raise 'Dirty git tree'
        end

        strategy.git "checkout #{branch}"
        info "Pulling from #{branch}"
        strategy.git "pull #{fetch(:git_remote, 'origin')} #{branch}"
        File.write(release_path.join('REVISION'),"#{branch}-#{tag_name}")
      end
    end
  end

  desc 'add git tags for each successful deployment'
  after :cleanup, :tagdeploy do
    run_locally do
      if ENV['NO_DEPLOYTAGS'] || fetch(:no_deploytags, false)
        info "[deploytags] Skipping deploytags"
      else
        tag_name = CapistranoDeploytags::Helper.git_tag_for(fetch(:stage))
        latest_revision = fetch(:current_revision)
        branch = fetch(:branch, false)
        commit_message = CapistranoDeploytags::Helper.commit_message(latest_revision, fetch(:stage))

        unless fetch(:sshkit_backend) ==  SSHKit::Backend::Printer # unless --dry-run flag present
          strategy.git "tag -a #{tag_name} -m \"#{commit_message}\" #{latest_revision}"
          strategy.git "push #{fetch(:git_remote, 'origin')} #{tag_name}"
        end
        info "[cap-deploy-tagger] Tagged #{latest_revision} with #{tag_name}"
      end
    end
  end
end
