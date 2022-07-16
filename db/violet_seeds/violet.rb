module VioletSeeds
  # keep static IDs in case we want to add/remove later
  ASSETS = [
    { id: 1, filename: 'a-toi-website-illustration-desktop.png' },
    { id: 2, filename: 'a-toi-website-illustration-mobile.png' },
    { id: 3, filename: 'atoi_wordmark_logo.png' },
    { id: 4, filename: 'coc-image@2x.png' },
    { id: 5, filename: 'coc-image-mobile@2x.png' },
    { id: 6, filename: 'coc_logo.png' },
    { id: 7, filename: 'code-first-icon@2x.png' },
    { id: 8, filename: 'collab-icon@2x.png' },
    { id: 9, filename: 'cta-bg-mobile.png' },
    { id: 10, filename: 'cta-bg.png' },
    { id: 11, filename: 'fixed-cost-icon@2x.png' },
    { id: 12, filename: 'github-logo.png' },
    { id: 13, filename: 'header-bg-mobile.png' },
    { id: 14, filename: 'header-bg.png' },
    { id: 15, filename: 'marked-image@2x.png' },
    { id: 16, filename: 'marked-image-mobile@2x.png' },
    { id: 17, filename: 'marked-logo.png' },
    { id: 18, filename: 'nikean-image@2x.png' },
    { id: 19, filename: 'nikean-image-mobile@2x.png' },
    { id: 20, filename: 'Nikean-Logo-White.png' },
    { id: 21, filename: 'oss-icon@2x.png' },
    { id: 22, filename: 'restarone-footer-logo.png' },
    { id: 23, filename: 'sanjay-desktop-1.png' },
    { id: 24, filename: 'sanjay-mobile.png' },
    { id: 25, filename: 'storage-icon@2x.png' },
    { id: 26, filename: 'unlimited-email-icon@2x.png' },
    { id: 27, filename: 'violet-rails-vertical-logo.png' },
    { id: 28, filename: 'your-idea-illustration.png' }
  ]

  SITE_CSS = <<-CSS
@import url('https://fonts.googleapis.com/css2?family=Karla:wght@400;500;800&display=swap');

.nav-link {
  font: normal normal normal 16px/19px Karla;
  letter-spacing: 0px;
  color: #050711 !important;
}

.navbar-light {
  background-color: #FFFFFF !important;
}

.logo {
    max-width: 115px; 
}

nav.navbar {
  box-shadow: 0px 30px 60px #6f5afe1f;
  border: 2px solid #6f5afe33;
  border-radius: 5px;
}

header {
  position: fixed;
  top: 10px;
  left: 0;
  z-index: 1020;
}

.navbar-toggler {
  border: none;
  padding: 8px;
}
.navbar-toggler span {
  display: block;
  background-color: #050711;
  height: 2px;
  width: 16px;
  margin-top: 3px;
  margin-bottom: 3px;
  position: relative;
  left: 0;
  opacity: 1;
  transition: all 0.35s ease-out;
  transform-origin: center left;
  border-radius: 1px;
}

.navbar-toggler span:nth-child(1) {
  margin-top: 0.3em;
}

.navbar-toggler:not(.collapsed) span:nth-child(1) {
  transform: translate(15%, -25%) rotate(45deg);
}

.navbar-toggler:not(.collapsed) span:nth-child(2) {
  opacity: 0;
}
.navbar-toggler:not(.collapsed) span:nth-child(3) {
  transform: translate(15%, 33%) rotate(-45deg);
}

.navbar-toggler span:nth-child(1) {
  transform: translate(0%, 0%) rotate(0deg);
}

.navbar-toggler span:nth-child(2) {
  opacity: 1;
}

.navbar-toggler span:nth-child(3) {
  transform: translate(0%, 0%) rotate(0deg);
}
.btn-demo {
  padding: 9px 15px;
  font: normal normal bold 14px/17px Karla;
}

.navbar-collapse > hr {
  margin: 1rem 0 0.5rem;
  border-top: 2px solid #6f5afe;
  opacity: 0.2;
}


footer {
  background: #EDEBFF 0% 0% no-repeat padding-box;
}

/* for button primary hover effect*/
.btn-primary {
  position: relative;
  background: transparent linear-gradient(76deg, #6F5AFE 0%, #A75AFE 100%) 0% 0% no-repeat padding-box !important;
  z-index: 1;
  border-radius: 5px !important;
  opacity: 1 !important;
  border: none;
}

.btn-primary::before {
  position: absolute;
  content: "";
  top: 0;
  right: 0;
  bottom: 0;
  left: 0;
  background: transparent linear-gradient(76deg, #8B7AFE 0%, #B87AFE 100%) 0% 0% no-repeat padding-box;
  border-radius: 5px;
  z-index: -1;
  transition: opacity 0.1s linear;
  opacity: 0;
}

.btn-primary:hover::before {
  opacity: 1 !important;
}

.badge-primary {
  border: 1px solid #E01A4F;
  border-radius: 2px;
  opacity: 1;
}

.text-primary {
  color: #6F5AFE !important;
}

/* for button secondary hover effect*/

.btn-secondary {
  border: 1px solid #6F5AFE;
  border-radius: 5px;
  opacity: 1;
  background: #050711 0% 0% no-repeat padding-box;
}

.btn-secondary::before {
  position: absolute;
  content: "";
  top: 0;
  right: 0;
  bottom: 0;
  left: 0;
    background: #6F5AFE33 0% 0% no-repeat padding-box;
  border-radius: 5px;
  z-index: -1;
  transition: opacity 0.1s linear;
  opacity: 0;
}

.btn-secondary:hover::before {
  opacity: 1 !important;
}


.list-group-item.active {
  border: 1px solid var(--ua-red);
  border: 1px solid #E01A4F;
  border-radius: 2px;
  opacity: 1;
  background: none;
  color: #E01A4F;
}
.text-danger {
  color: #E01A4F;
}
.jumbotron.jumbo-primary {
  background-color: #FFFFFF;
}
.jumbotron.jumbo-secondary {
  background-color: #EDEBFF;
}

main.main {
    padding-top: 25px;
}
.list-group-item {
  background: transparent linear-gradient(73deg, #A75AFE33 0%, #6F5AFE00 100%) 0% 0% no-repeat padding-box;
  border: 1px solid #A75AFE66;
  border-radius: 2px;
  opacity: 1;
}
.card-header > .img-fluid {
    max-width: 50px;
}

@media (max-width: 992px) {
  header.container {
    padding: 0 6px;
  }
  
  main.main {
    padding-top: 25px;
}
}

@media (min-width: 992px) {
  .navbar-expand-lg .navbar-nav .nav-link {
    padding-right: 20px;
    padding-left: 20px;
  }
}

.footer-bottom {
  background: #e0ddfb;
}

.footer-logo {
  max-width: 121px;
}

.footer-bottom .logo {
  max-width: 21px;
}

.nav-link.current {
  color: #6f5afe !important;
}

.cursor-pointer {
  cursor: pointer;
}

.navbar-brand {
  margin-right: 10px;
}
CSS
  LANDING_PAGE_CONTENT = <<-PAGECONTENT
<style>
@import url('https://fonts.googleapis.com/css2?family=Karla:wght@400;500;800&display=swap');
body > ul.nav {
display: none !important;
}
body {
  font-family: Karla;
}
p {
  font-size: 16px;
  line-height: 19px;
  font-family: Karla;
  color: #050711;
}
.fw-500 {
  font-weight: 500;
}
h1 {
  font: normal normal 800 64px/75px Karla;
  color: #050711;
  letter-spacing: 0;
}
h2 {
  font: normal normal 800 42px/50px Karla;
}
h3 {
  font: normal normal 800 36px/42px Karla;
}
h5 {
  font: normal normal 800 24px/28px Karla;
}
.badge {
  font: normal normal 800 16px/19px Karla;
  padding: 6px 12px;
}
main.main,
.main > .container,
main.benefits,
.benefits > .container {
  position: relative;
  z-index: 5;
}
main.main .bg-image {
  position: absolute;
  bottom: 0;
  right: 0;
  z-index: 1;
}
main.benefits .bg-image {
  position: absolute;
  bottom: -45px;
  left: 0;
  z-index: 1;
}
.bg-image {
  object-fit: contain;
}
.text-accent {
  color: #6f5afe;
}
.navbar-light {
  background-color: #ffffff !important;
}
.nav-link {
  font: normal normal normal 16px/19px Karla;
  letter-spacing: 0px;
  color: #050711 !important;
}
.logo {
  max-width: 115px;
}
.lead {
  font: normal normal normal 16px/19px Karla;
  letter-spacing: 0px;
  color: #050711;
  opacity: 0.6;
}
footer {
  background: #edebff 0% 0% no-repeat padding-box;
}
.get-started {
  background: #050711 !important;
  border-radius: 10px;
  padding: 90px 0;
}
.get-started > p, .get-started > h2 {
  max-width: 537px;
  margin: auto;
}
/* for button primary hover effect*/
.btn-primary {
  position: relative;
  background: transparent linear-gradient(76deg, #6f5afe 0%, #a75afe 100%) 0% 0%
    no-repeat padding-box !important;
  z-index: 1;
  border-radius: 5px !important;
  opacity: 1 !important;
  border: none;
  font: normal normal bold 14px/17px Karla;
}
.btn-lg {
  font: normal normal bold 16px/19px Karla;
  padding: 15px 25px;
}
.btn-primary::before {
  position: absolute;
  content: "";
  top: 0;
  right: 0;
  bottom: 0;
  left: 0;
  background: transparent linear-gradient(76deg, #8b7afe 0%, #b87afe 100%) 0% 0%
    no-repeat padding-box;
  border-radius: 5px;
  z-index: -1;
  transition: opacity 0.1s linear;
  opacity: 0;
}
.btn-primary:hover::before {
  opacity: 1 !important;
}
.badge-primary {
  border: 1px solid #e01a4f;
  border-radius: 2px;
  opacity: 1;
}
.text-primary {
  color: #6f5afe !important;
}
/* for button secondary hover effect*/
.btn-secondary {
  border: 1px solid #6f5afe;
  border-radius: 5px;
  opacity: 1;
  background: #050711 0% 0% no-repeat padding-box;
}
.btn-secondary::before {
  position: absolute;
  content: "";
  top: 0;
  right: 0;
  bottom: 0;
  left: 0;
  background: #6f5afe33 0% 0% no-repeat padding-box;
  border-radius: 5px;
  z-index: -1;
  transition: opacity 0.1s linear;
  opacity: 0;
}
.btn-secondary:hover::before {
  opacity: 1 !important;
}
.btn-shadow {
  box-shadow: 0px 10px 40px #6f5afe59;
}
.list-group-item.active {
  border: 1px solid var(--ua-red);
  border: 1px solid #e01a4f;
  border-radius: 2px;
  opacity: 1;
  background: none;
  color: #e01a4f;
}
.text-danger {
  color: #e01a4f;
}
.jumbotron.jumbo-primary {
  background-color: #ffffff;
}
.jumbotron.jumbo-secondary {
  background-color: #edebff;
}
.list-group-item {
  background: transparent linear-gradient(73deg, #a75afe33 0%, #6f5afe00 100%)
    0% 0% no-repeat padding-box;
  border: 1px solid #a75afe66;
  border-radius: 2px;
  opacity: 1;
}
.benefits .card {
  box-shadow: 0px 20px 30px #6f5afe14;
  border: 1px solid #6f5afe66;
  border-radius: 10px;
  margin-bottom: 32px;
}
.first-col .card {
  margin-right: 22px;
}
.second-col .card {
  margin-right: 10px;
  margin-left: 10px;
}
.third-col .card {
  margin-left: 22px;
}
.card-header {
  padding-bottom: 0;
}
.card-header > .img-fluid {
  max-width: 36px;
}
nav.navbar {
  box-shadow: 0px 30px 60px #6f5afe1f;
  border: 2px solid #6f5afe33;
  border-radius: 5px;
}
header {
  position: sticky;
  top: 10px;
  left: 0;
  z-index: 1020;
  min-height: 100px;
}
header > .container {
	position: absolute;
  left: 0;
  right: 0;
}
.navbar-toggler {
  border: none;
  padding: 8px;
}
.navbar-toggler span {
  display: block;
  background-color: #050711;
  height: 2px;
  width: 16px;
  margin-top: 3px;
  margin-bottom: 3px;
  position: relative;
  left: 0;
  opacity: 1;
  transition: all 0.35s ease-out;
  transform-origin: center left;
  border-radius: 1px;
}
.navbar-toggler span:nth-child(1) {
  margin-top: 0.3em;
}
.navbar-toggler:not(.collapsed) span:nth-child(1) {
  transform: translate(15%, -25%) rotate(45deg);
}
.navbar-toggler:not(.collapsed) span:nth-child(2) {
  opacity: 0;
}
.navbar-toggler:not(.collapsed) span:nth-child(3) {
  transform: translate(15%, 33%) rotate(-45deg);
}
.navbar-toggler span:nth-child(1) {
  transform: translate(0%, 0%) rotate(0deg);
}
.navbar-toggler span:nth-child(2) {
  opacity: 1;
}
.navbar-toggler span:nth-child(3) {
  transform: translate(0%, 0%) rotate(0deg);
}
.btn-demo {
  padding: 9px 15px;
}
.navbar-collapse > hr {
  margin: 1rem 0 0.5rem;
  border-top: 2px solid #6f5afe;
  opacity: 0.2;
}
.jumbo-top {
  padding-top: 35px;
}
.bg-grey {
  background-color: #edebff;
}
.embed-responsive {
  border-radius: 10px;
}
.product-img {
  display: block;
  transition: all 0.6s ease-out;
}
.product-img:hover {
  transform: scale(1.05);
}
.products .product-img img {
  max-width: 100%;
  height: auto;
  object-fit: contain;
}
.img-div {
  padding-left: 0;
}
@media (max-width: 992px) {
  header.container {
    padding: 0 6px;
  }
}
@media (min-width: 992px) {
  .navbar-expand-lg .navbar-nav .nav-link {
    padding-right: 20px;
    padding-left: 20px;
  }
}
@media (max-width: 767.98px) {
  .badge {
    font: normal normal 800 14px/17px Karla;
    padding: 5px 10px;
  }
  h1 {
    font: normal normal 800 46px/54px Karla;
  }
  h2 {
    font: normal normal 800 28px/33px Karla;
  }
  h3 {
    font: normal normal 800 26px/31px Karla;
  }
  h5 {
    font: normal normal 800 22px/26px Karla;
  }
  .btn-lg {
    font: normal normal bold 14px/17px Karla;
    padding: 15px 25px;
  }
  .jumbo-top {
    padding-top: 0;
  }
  .benefits .card {
    margin-left: 0 !important;
    margin-right: 0 !important;
  }
  .card-header > .img-fluid {
    max-width: 30px;
  }
  .get-started {
    padding: 30px;
  }
  .get-started > p {
    max-width: none;
  }
  .get-started a {
    white-space: nowrap;
    padding: 15px 20px;
  }
  .img-div {
    padding: 0;
  }
}
.footer-bottom {
  background: #e0ddfb;
}
.footer-logo {
  max-width: 121px;
}
.footer-bottom .logo {
  max-width: 21px;
}
.nav-link.current {
  color: #6f5afe;
}
.cursor-pointer {
  cursor: pointer;
}
.navbar-brand {
  margin-right: 10px;
}
</style><main class="main">
<div class="container">
	<div class="jumbotron jumbo-top bg-transparent px-0 mb-0">
		<div class="row d-flex justify-content-center align-items-center">
			<div class="col-xl-6 flex-column d-flex justify-content-center align-items-start">
				<div>
					<div class="mb-2">
						<span class="badge badge-primary bg-transparent text-danger">VIOLET RAILS</span>
					</div>
					<h1 class="text-capitalize">A Feature Rich <br><span class="text-accent">Web Platform</span><br>
					</h1>
					<p class="lead mt-3"> For hosting your next big idea
					</p>
				</div>
				<div class="d-flex align-items-center my-5">
					<a href="/forum" class="btn btn-lg btn-primary btn-shadow">Forum</a>
					<a href="https://github.com/restarone/violet_rails" class="d-flex align-items-center btn btn-lg font-weight-bold bg-transparent">
					<img src="{{ cms:file_link 12 }}" class="img mr-2">
					GitHub
					</a>
				</div>
			</div>
			<div class="col-xl-6 d-flex align-items-center">
				{{ cms:file_link 28, as: image, class: "img-fluid" }}
			</div>
		</div>
		<p class="m-0 p-0 d-inline fw-500">
			This website + app is built with
		</p>
		<p class="d-inline text-primary fw-500">Violet Rails
		</p>
	</div>
</div>
<div class="bg-image">
	<img src="{{ cms:file_link 14}}" class="w-100 h-100 d-none d-md-block" alt="">
	<img src="{{ cms:file_link 13}}" class="w-100 h-100 d-md-none" alt="">
</div></main><main class="bg-grey">
<div class="container">
	<div class="jumbotron m-0 px-0 bg-transparent">
		<div class="row">
			<div class="col-xl-7 d-flex align-items-center">
				<div class="embed-responsive embed-responsive-16by9 h-100">
					<iframe class="embed-responsive-item" src="https://www.youtube.com/embed/hExwxHabdxI" allowfullscreen="">
					</iframe>
				</div>
			</div>
			<div class="col-xl-5 flex-column d-flex justify-content-center align-items-start">
				<div class="py-4 px-lg-3">
					<div>
						<div class="mb-2">
							<span class="badge badge-primary bg-transparent text-danger">What is Violet Rails?</span>
						</div>
						<h2><span class="text-accent">Calling Builders</span> and Self-Starters
						</h2>
						<p class="lead mt-3">If you are looking to validate a new idea or present a new
                business
                to
                the world, Violet Rails
                is the platform for you. It is a complete web content management engine that includes professional
                email,
                blog, forum, and collaboration tools packaged into your web domain. Take a look at the video demo.
						</p>
					</div>
					<div class="d-flex text-left mt-4">
						<a href="https://restarone.com/contact/new" class="btn btn-shadow btn-lg btn-primary">Contact Us</a>
					</div>
				</div>
			</div>
		</div>
	</div>
</div></main><main class="bg-grey">
<div class="container">
	<div class="jumbotron m-0 px-0 bg-transparent">
		<div class="row d-flex justify-content-center align-items-center">
			<div class="col-xl-5 flex-column d-flex justify-content-center align-items-start">
				<div>
					<div class="mb-2">
						<span class="badge badge-primary bg-transparent text-danger">What is it good for?</span>
					</div>
					<h2>
					The Home-Base For <span class="text-accent">Your Next Idea</span>
					</h2>
					<p class="lead mt-3" style="opacity: 0.6;">Being an open-source platform, you can start with a base
              deployment
              and
              customize it to the
              needs of your business/project. Empower your technical team with a productive Ruby on Rails template.
					</p>
				</div>
				<div class="d-flex text-left my-4">
					<a href="https://github.com/restarone/violet_rails/" class="btn btn-shadow btn-lg btn-primary">View on
              GitHub
					</a>
				</div>
			</div>
			<div class="col-xl-7 d-flex align-items-center justify-content-center">
				<ul class="list-group w-100 pl-lg-3">
					<li class="list-group-item my-1">Static web hosting</li>
					<li class="list-group-item my-1">Email</li>
					<li class="list-group-item my-1">E-commerce</li>
					<li class="list-group-item my-1">Blogging</li>
					<li class="list-group-item my-1">Forums</li>
					<li class="list-group-item my-1">File storage</li>
					<li class="list-group-item my-1">Collaborating with your team</li>
					<li class="list-group-item my-1">Tip top Search Engine Optimization</li>
					<li class="list-group-item my-1">Be in control of your data</li>
				</ul>
			</div>
		</div>
	</div>
</div></main><main class="benefits">
<div class="container">
	<div class="jumbotron bg-transparent m-0 px-0">
		<div class="row d-flex flex-column justify-content-center align-items-center">
			<div class="col text-lg-center mb-2">
				<span class="badge badge-primary bg-transparent text-danger">BENEFITS OF VIOLET RAILS</span>
			</div>
			<div class="col text-lg-center">
				<h2 class="d-block font-weight-bold px-lg-5">
				What About Wix, Wordpress, Gsuite and Everyone Else?
				</h2>
			</div>
		</div>
		<div class="row my-5 d-flex flex-wrap mx-0">
			<div class="col-md-4 p-0 first-col">
				<div class="card">
					<div class="card-header bg-transparent border-0">
						{{ cms:file_link 26, as: image, class: 'img-fluid' }}
					</div>
					<div class="card-body">
						<h5 class="card-title font-weight-bold mb-2">Unlimited email addresses</h5>
						<p class="card-text">After connecting to your domain, you can create and assign as many email addresses as
                you
                need at no extra cost
						</p>
					</div>
				</div>
				<div class="card">
					<div class="card-header bg-transparent border-0">
						{{ cms:file_link 21 , as: image, class: 'img-fluid' }}
					</div>
					<div class="card-body">
						<h5 class="card-title font-weight-bold">Built with top-shelf open source software</h5>
						<p class="card-text">Violet Rails is supported by a slew of battle-hardened frameworks such as Rails,
                Sidekiq,
                Sinatra and Devise (just to name a few)
						</p>
					</div>
				</div>
			</div>
			<div class="col-md-4 p-0 second-col">
				<div class="card">
					<div class="card-header bg-transparent border-0">
						{{ cms:file_link 11, as: image, class: 'img-fluid' }}
					</div>
					<div class="card-body">
						<h5 class="card-title font-weight-bold mb-2">Fixed cost and no vendor lock-in<br></h5>
						<p class="card-text">Depending on the configuration, a violet server can be deployed for as little as $7 a
                month
                all-in on any major cloud provider
						</p>
					</div>
				</div>
				<div class="card">
					<div class="card-header bg-transparent border-0">
						{{ cms:file_link 8, as: image, class: 'img-fluid' }}
					</div>
					<div class="card-body">
						<h5 class="card-title font-weight-bold mb-2">Collaborative, isolated, and secure<br></h5>
						<p class="card-text lead">Invite your team or department in your organization with a flexible user
                management
                system
                both at the domain and subdomain levels
						</p>
					</div>
				</div>
			</div>
			<div class="col-md-4 p-0 third-col">
				<div class="card">
					<div class="card-header bg-transparent border-0">
						{{ cms:file_link 7, as: image, class: 'img-fluid' }}
					</div>
					<div class="card-body">
						<h5 class="card-title font-weight-bold mb-2">A code first platform</h5>
						<p class="card-text lead">Build web pages with HTML, CSS and Javascript with out of the box support for
                Bootstrap
                4
                and jQuery
						</p>
					</div>
				</div>
				<div class="card">
					<div class="card-header bg-transparent border-0">
						{{ cms:file_link 25, as: image, class: 'img-fluid' }}
					</div>
					<div class="card-body">
						<h5 class="card-title font-weight-bold mb-2">Safe and scalable storage</h5>
						<p class="card-text lead">Depending on the specific configuration, Violet Rails can either use the disk on
                an
                on-premise server or generic service (such as AWS S3)
							<br>
						</p>
					</div>
				</div>
			</div>
		</div>
	</div>
</div>
<div class="bg-image">
	<img src="{{ cms:file_link 10 }}" class="w-100 h-100 d-none d-md-block" alt="">
	<img src="{{ cms:file_link 9 }}" class="w-100 h-100 d-md-none" alt="">
</div></main><main class="products-section" id="products-section">
<div class="container text-md-center">
	<div class="mb-2">
		<span class="badge badge-primary bg-transparent text-danger">Built with Violet Rails</span>
	</div>
	<h2 class="mb-5">
	Custom Development <span class="text-accent">Made Easier</span>
	</h2>
	<div class="products">
		<div class="row flex-lg-row-reverse mb-5">
			<div class="col-md-4 d-flex align-items-center">
				<div class="product-detail text-left">
					<div class="product-logo mb-3">
						<img src="{{ cms:file_link 6 }}" alt="" width="121">
					</div>
					<h3 class="mb-2">Coffee Oysters Champagne</h3>
					<p class="lead mb-4">A chic website for a glamorous oyster bar in Toronto, featuring a custom-design, online event booking and CRM integration.
					</p>
					<a href="https://www.sipshucksip.com/" class="btn btn-primary btn-lg btn-shadow" target="_blank">VISIT WEBSITE</a>
				</div>
			</div>
			<div class="col-md-8 img-div">
				<a href="https://www.sipshucksip.com/" class="product-img" target="_blank">
				<img src="{{ cms:file_link 4 }}" class="d-none d-sm-block" alt="" width="742" height="639">
				<img src="{{ cms:file_link 5 }}" alt="" class="d-sm-none">
				</a>
			</div>
		</div>
		<div class="row mb-5">
			<div class="col-lg-4 d-flex align-items-center">
				<div class="product-detail text-left">
					<div class="product-logo mb-3">
						<img src="{{ cms:file_link 17 }}" alt="" width="170">
					</div>
					<h3 class="mb-2">Marked Restaurant</h3>
					<p class="lead mb-4">A bold website for a premier grill-house in Toronto, featuring a custom-design, online event booking and CRM integration.
					</p>
					<a href="https://www.markedrestaurant.com/" class="btn btn-primary btn-lg btn-shadow" target="_blank">VISIT WEBSITE</a>
				</div>
			</div>
			<div class="col-lg-8 img-div">
				<a href="https://www.markedrestaurant.com/" target="_blank" class="product-img">
				<img src="{{ cms:file_link 15 }}" alt="" class="d-none d-sm-block" width="742" height="639">
				<img src="{{ cms:file_link 16 }}" alt="" class="d-sm-none">
				</a>
			</div>
		</div>
		<div class="row flex-lg-row-reverse mb-5">
			<div class="col-md-4 d-flex align-items-center">
				<div class="product-detail text-left">
					<div class="product-logo mb-3">
						<img src="{{ cms:file_link 3 }}" alt="" width="100">
					</div>
					<h3 class="mb-2">a toi<br></h3>
					<p class="lead mb-4">A creative and unique website for Toronto's best worst-kept secret<br>
					</p>
					<a href="https://a-toi.ca/" class="btn btn-primary btn-lg btn-shadow" target="_blank">VISIT WEBSITE</a>
				</div>
			</div>
			<div class="col-md-8 img-div">
				<a href="https://a-toi.ca/" class="product-img" target="_blank">
				<img src="{{ cms:file_link 1 }}" class="d-none d-sm-block" alt="" width="742" height="639">
				<img src="{{ cms:file_link 2 }}" alt="" class="d-sm-none">
				</a>
			</div>
		</div>
		<div class="row mb-5">
			<div class="col-lg-4 d-flex align-items-center">
				<div class="product-detail text-left">
					<h3 class="mb-2">Sanjay Singhal</h3>
					<p class="lead mb-4">A simple and elegant website for showcasing the legacy of one of Canada's most sought after and successful startup investors.
					</p>
					<a href="https://www.sanjaysinghal.com/" class="btn btn-primary btn-lg btn-shadow" target="_blank">VISIT WEBSITE</a>
				</div>
			</div>
			<div class="col-lg-8 img-div">
				<a href="https://www.sanjaysinghal.com/" target="_blank" class="product-img">
				<img src="{{ cms:file_link 23 }}" alt="" class="d-none d-sm-block">
				<img src="{{ cms:file_link 24 }}" alt="" class="d-sm-none w-100">
				</a>
			</div>
		</div>
		<div class="row flex-lg-row-reverse mb-5">
			<div class="col-lg-4 d-flex align-items-center">
				<div class="product-detail text-left">
					<div class="product-logo mb-3">
						<img src="{{ cms:file_link 20 }}" alt="" width="219">
					</div>
					<h3 class="mb-2">Nikean Foundation</h3>
					<p class="lead mb-4">An eclectic website for a foundation dedicated to advancing psychedelic science.
					</p>
					<a href="https://nikean.org/" class="btn btn-primary btn-lg btn-shadow" target="_blank">VISIT WEBSITE</a>
				</div>
			</div>
			<div class="col-lg-8 img-div">
				<a href="https://nikean.org/" target="_blank" class="product-img">
				<img src="{{ cms:file_link 18 }}" class="d-none d-sm-block" alt="" width="742" height="639">
				<img src="{{ cms:file_link 19 }}" alt="" class="d-sm-none">
				</a>
			</div>
		</div>
	</div>
</div></main><main class="container d-none d-lg-block">
<div class="text-white text-center get-started">
	<h2 class="mb-3">Ready to Get Started?</h2>
	<p class="text-white lead">If you want to deploy your own Violet Rails application to your domain, check out the
      documentation
      on
      GitHub or reach out to us for a fully managed solution to fit your needs
	</p>
	<div class="d-flex align-items-center justify-content-center mt-5">
		<a href="https://restarone.com/contact/new" class="btn btn-lg btn-primary">Contact Us</a>
		<a href="https://github.com/restarone/violet_rails/wiki" class="btn btn-lg ml-3 btn-secondary">
		Documentation
		</a>
	</div>
</div></main><main class="container d-lg-none">
<div class="text-white get-started">
	<h2 class="mb-3">See it in action, <br><span class="text-primary">get started</span></h2>
	<p class="text-white">
		Right now, you are looking at the "public facing" side of an Violet Rails application. Sign up for the demo to see
      the rest of the features as a tenant of this domain.
		<br><br> If you want to read the dev blog or the forum, see below.
	</p>
	<div class="d-flex align-items-center justify-content-center mt-4">
		<a href="https://restarone.com/contact/new" target="_blank" class="btn btn-lg btn-primary">GET A DEMO</a>
		<a href="/blog" class="btn btn-lg ml-3 btn-secondary">
		SEE OUR BLOG
		</a>
	</div>
</div></main>
PAGECONTENT
  NAVBAR_CONTENT = <<-CONTENT
<style>
  @import url('https://fonts.googleapis.com/css2?family=Karla:wght@400;500;800&display=swap');

.nav-link {
  font: normal normal normal 16px/19px Karla;
  letter-spacing: 0px;
  color: #050711 !important;
}

.navbar-light {
  background-color: #FFFFFF !important;
}

.logo {
	max-width: 115px; 
}

nav.navbar {
  box-shadow: 0px 30px 60px #6f5afe1f;
  border: 2px solid #6f5afe33;
  border-radius: 5px;
}

header {
  position: sticky;
  top: 10px;
  left: 0;
  z-index: 1020;
  min-height: 125px;
}
header > .container {
	position: absolute;
  left: 0;
  right: 0;
}

.navbar-toggler {
  border: none;
  padding: 8px;
}
.navbar-toggler span {
  display: block;
  background-color: #050711;
  height: 2px;
  width: 16px;
  margin-top: 3px;
  margin-bottom: 3px;
  position: relative;
  left: 0;
  opacity: 1;
  transition: all 0.35s ease-out;
  transform-origin: center left;
  border-radius: 1px;
}

.navbar-toggler span:nth-child(1) {
  margin-top: 0.3em;
}

.navbar-toggler:not(.collapsed) span:nth-child(1) {
  transform: translate(15%, -25%) rotate(45deg);
}

.navbar-toggler:not(.collapsed) span:nth-child(2) {
  opacity: 0;
}
.navbar-toggler:not(.collapsed) span:nth-child(3) {
  transform: translate(15%, 33%) rotate(-45deg);
}

.navbar-toggler span:nth-child(1) {
  transform: translate(0%, 0%) rotate(0deg);
}

.navbar-toggler span:nth-child(2) {
  opacity: 1;
}

.navbar-toggler span:nth-child(3) {
  transform: translate(0%, 0%) rotate(0deg);
}
.btn-demo {
  padding: 9px 15px;
  font: normal normal bold 14px/17px Karla;
}

.navbar-collapse > hr {
  margin: 1rem 0 0.5rem;
  border-top: 2px solid #6f5afe;
  opacity: 0.2;
}

@media (max-width: 992px) {
  header.container {
    padding: 0 6px;
  }
  header {
  	min-height: 98px;
	}
}

@media (min-width: 992px) {
  .navbar-expand-lg .navbar-nav .nav-link {
    padding-right: 20px;
    padding-left: 20px;
  }
}

.footer-bottom {
  background: #e0ddfb;
}

.footer-logo {
  max-width: 121px;
}

.footer-bottom .logo {
  max-width: 21px;
}

.nav-link.current {
  color: #6f5afe !important;
}

.cursor-pointer {
  cursor: pointer;
}

.navbar-brand {
  margin-right: 10px;
}
  
.footer-bottom .lead {
    font: normal normal normal 16px/19px Karla;
    letter-spacing: 0px;
    color: #050711;
    opacity: 0.6;
}
</style>
<header class="w-100">
    <div class="container">
    <nav class="navbar navbar-expand-lg navbar-light sticky-top d-flex justify-content-between">
        <div class="d-flex align-items-center">
            <a href="/" class="navbar-brand">
                <div class="logo d-none d-lg-block">
              		{{cms:snippet navbar-logo}}
      	        </div>
			
								<div class="d-lg-none logo">
  									{{cms:snippet logo-small}}
              	</div>
            </a>
            <div class="navbar-toggler cursor-pointer collapsed" data-toggle="collapse" data-target="#navbarNav"
                aria-controls="navbarNav" aria-expanded="false" aria-label="Toggle navigation">
                <span></span>
                <span></span>
                <span></span>
            </div>
        </div>
        <a href="https://www.restarone.com/contact" target="_blank"  class="btn-primary btn d-lg-none btn-demo">GET A DEMO</a>
        <div class="collapse navbar-collapse justify-content-center" id="navbarNav">
            <hr class="d-lg-none">
            <ul class="navbar-nav">
                <li class="nav-item">
                    <a class="nav-link" href="/">HOME</a>
                </li>
                <li class="nav-item">
                    <a class="nav-link" href="/blog">BLOG</a>
                </li>
                <li class="nav-item">
                    <a class="nav-link" href="/forum">FORUM</a>
                </li>
                <li class="nav-item">
                    <a class="nav-link scroll-link" data-id="products-section" href="/">EXAMPLES</a>
                </li>
            </ul>
        </div>

        <a href="https://www.restarone.com/contact" target="_blank" class="btn-primary btn d-none d-lg-block btn-demo">GET A DEMO</a>

    </nav>
  </div>
</header>
<script>
    var url = window.location.href;
    $('.nav-link').filter(function() {
        return this.href == url && !this.classList.contains("scroll-link");
    }).addClass('current');
  
  $(document).ready(function () {
    // Read the cookie and if it's defined scroll to id
    var scroll = sessionStorage.getItem('scroll');
    if(scroll){
        scrollToID(scroll, 1000);
        sessionStorage.removeItem('scroll')
    }
    // Handle event onclick, setting the cookie when the href != #
    $('.scroll-link').click(function (e) {
        e.preventDefault();
        $('.navbar-toggler').toggleClass('collapsed'); 

        if ( $('.navbar-collapse.collapse').hasClass('show')) {
          $('.navbar-collapse.collapse').toggleClass('show');
        }
      
        var id = $(this).data('id');
        var href = $(this).attr('href');
        if(this.href === url){
            scrollToID(id, 1000);
        }else{
            sessionStorage.setItem('scroll', id)
            window.location.href = href;
        }
    });

    // scrollToID function
    function scrollToID(id, speed) {
        var offSet = 120;
        var obj = $('#' + id);
        if (id === "main-section") {
          $('html,body').stop().animate({ scrollTop: 0 }, speed);
				} else if(obj.length){
          var offs = obj.offset();
          var targetOffset = offs.top - offSet;
          $('html,body').stop().animate({ scrollTop: targetOffset }, speed);
        }
    }
});
</script>
CONTENT
  FOOTER_CONTENT = <<-CONTENT
<footer class="mt-5 pt-5 d-flex flex-column justify-content-center align-items-center">
    <div class="text-center">
    <img src="{{ cms:file_link 41 }}" class="logo" alt="Violet Rails"/>
    </div>
    <ul class="nav justify-content-center my-5">
        <li class="nav-item">
            <a class="nav-link text-dark" href="/">Home</a>
        </li>
        <li class="nav-item">
            <a class="nav-link text-dark" href="/blog">Blog</a>
        </li>
        <li class="nav-item">
            <a class="nav-link text-dark" href="/forum">Forum</a>
        </li>
        <li class="nav-item">
            <a class="nav-link text-dark" href="https://github.com/restarone/violet_rails">GitHub</a>
        </li>
        <li class="nav-item">
            <a class="nav-link text-dark" href="https://restarone.com/contact">Contact Us</a>
        </li>
    </ul>
    <div class="d-flex w-100 py-3 footer-bottom flex-column justify-content-center align-items-center">
        <a href="https://restarone.com" class="d-flex justify-content-start align-items-center">
         	<img src="{{ cms:file_link 42 }}" class="logo d-block" alt="Violet Rails"/>
            <p class="lead m-2 text-dark">
                Built and supported by Restarone Inc.
            </p>
        </a>
    </div>
</footer>
CONTENT
end
