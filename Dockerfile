FROM quay.io/perl/base-os:v3.0.2

ENV RTVERSION 4.4.2

RUN addgroup rt && adduser -D -G rt rt

RUN apk --no-cache upgrade; apk add --no-cache gnupg emacs-nox \
   gd-dev graphviz perl-graphviz perl-gd \
   ssmtp

# get some dependencies in the image and cached
RUN cpanm HTML::Mason Moose Locale::Maketext::Fuzzy DBIx::SearchBuilder HTML::Formatter \
  Crypt::X509 String::ShellQuote Regexp::IPv6 Text::Password::Pronounceable \
  Regexp::Common::net::CIDR Data::ICal Symbol::Global::Name HTML::RewriteAttributes \
  Text::WikiFormat Text::Quoted HTML::Quoted UNIVERSAL::require Module::Versions::Report \
  Time::ParseDate MIME::Types Data::GUID Text::Wrapper \
  IO::Socket::SSL JSON::XS JSON LWP::Simple XML::RSS Regexp::Common \
  Plack Plack::Handler::Starlet Log::Dispatch Locale::Maketext Encode \
  Digest::SHA Digest::MD5 DBI CGI CGI::PSGI Mail::Header Net::CIDR \
  JavaScript::Minifier::XS HTML::Scrubber CPAN \
  Term::ReadKey Apache::Session CSS::Squish Date::Extract DateTime::Format::Natural \
  CSS::Minifier::XS Convert::Color Business::Hours Email::Address::List CGI::Emulate::PSGI \
  Crypt::Eksblowfish Date::Manip Scope::Upper HTML::Mason::PSGIHandler \
  Data::Page::Pageset Tree::Simple MIME::Entity Role::Basic  && rm -fr ~/.cpanm

# modules with problems installing
RUN cpanm HTML::FormatText::WithLinks::AndTables HTML::FormatText::WithLinks && rm -fr ~/.cpanm 

RUN cpanm GraphViz GD && rm -fr ~/.cpanm

# test fails on Alpine, ignore them...
RUN cpanm -n PerlIO::eol && rm -fr ~/.cpanm

# for GnuPG::Interface
RUN cpanm MooX::late MooX::HandlesVia && rm -fr ~/.cpanm
RUN cpanm -f GnuPG::Interface && rm -fr ~/.cpanm

# autoconfigure cpan shell for RT installer
RUN cpan < /dev/null
RUN cpan CPAN

RUN mkdir /usr/src
RUN curl -Ls https://download.bestpractical.com/pub/rt/release/rt-$RTVERSION.tar.gz | tar -C /usr/src -xz

WORKDIR /usr/src/rt-$RTVERSION

ADD net-ssl.patch /tmp/
RUN patch -p1 < /tmp/net-ssl.patch && rm /tmp/net-ssl.patch

RUN ./configure \
   --prefix=/opt/rt \
   --with-web-handler=standalone \
   --with-db-type=mysql \
   --with-db-rt-host=mysql \
   --with-web-user=rt \
   --with-web-group=rt

#   --enable-externalauth \
#   --enable-gpg --enable-smime \

RUN make fixdeps && rm -fr ~/.cpan
RUN make testdeps
RUN make install

ENV PERL5LIB=/opt/rt/lib

# For RT::Extension::REST2
RUN cpanm Path::Dispatcher MooseX::Role::Parameterized Web::Machine Module::Path Pod::POM && rm -fr ~/.cpanm
RUN cpanm -f Test::WWW::Mechanize::PSGI && rm -fr ~/.cpanm

RUN cpanm RT::Authen::Token RT::Extension::MergeUsers && rm -fr ~/.cpanm

# tests fail if a valid database hasn't been setup
RUN cpanm -f RT::Extension::REST2 && rm -fr ~/.cpanm

RUN perl -i -pe 's{^mailhub=.*}{mailhub=smtp}' /etc/ssmtp/ssmtp.conf

WORKDIR /opt/rt

ADD run /opt/rt/

CMD /opt/rt/run
