# $Id: Makefile.PL,v 1.2 2000/09/09 21:16:56 chardin Exp $

use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'	=> 'Mail::QuoteWrap',
    'VERSION_FROM' => './lib/Mail/QuoteWrap.pm',
);
