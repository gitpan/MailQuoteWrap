# $Id: QuoteWrap.pm,v 1.2 2000/09/09 21:17:26 chardin Exp chardin $

package Mail::QuoteWrap;

=head1 NAME

B<Mail::QuoteWrap> - Provides quotification functionality for Usenet articles
and mail.

=head1 SYNOPSIS

    use Mail::QuoteWrap;
 
    ...

    my $columns = 72;                     # maximum column width of the post
    my $output_quotechar = ">";           # character to prepend to
                                          # quoted lines -- see quotify()
    my $input_quotechars = "<>:";         # characters to be recognized as
                                          # quotifiers when judging the
                                          # generation of a quote

    my $text = $news_article->body();     # get some body text somehow

    my $body = create Mail::QuoteWrap ($text, $columns, $output_quotechar,
                                     $input_quotechars, {});

    $body->quotify();
    $body->append("Me too!");

    my $newtext = $body->format();

=head1 DESCRIPTION

A B<Mail::QuoteWrap> object expects its text member to contain a reference to a
list of lines of text, such as the output of methods like
C<body News::Article()>.  It can then produce quotified output, optionally
prepended with the quote mark designated by I<output_quotechar>, within the
width specified by I<columns>.

B<Mail::QuoteWrap> specificially does not solve the following problems:

=over 4

=item

It does not handle munged quote characters, such as those produced
by the AOHell newsreader or similar gunge:

 >> This >is a second-generation quote, but it
 > looks >>like a nasty mix of first- and second->
 > generation >>material.

=item

It does not automatically detect and bypass news or mail headers.  That
is not the role of this object.

=item

It assumes a paragraph structure to the quoted text and doesn't try to enforce
any other.  If you want a module that detects document structure and deals
well with it, look at B<Text::Autoformat>.

=back

=head1 REQUIRES

This module uses B<Text::Format>.

=head1 BUGS

=over 4

=item

If I<input_quotechars> or I<output_quotechar> contain suckful characters
that regexp thinks it understands, all hell can break loose.

=item

B<Mail::QuoteWrap> may not deal well with Supercite-style quotification:

 Chuck> I believe everything I see written on toilet paper

is thought to be zeroth-generation (unquoted) material.

=back

=head1 AUTHOR

Chuck Hardin <chardin@savageoasis.fc.net>

=head1 COPYRIGHT

This module is copyright 2000, Chuck Hardin.

=head1 LICENSE

This module is distributed under version 2 of the GNU Public License.

=cut

use strict;
use Text::Format;

my $VERSION = '0.01';

=head1 Public class method

=head2 create

 public class
 (Mail::QuoteWrap) create(string[] text [,integer columns]
                          [,string output_quotechar] [,string input_quotechars]
                          [,hashref format_params])

This method creates a B<Mail::QuoteWrap> object populated with the
parameters passed in.  It returns a NULL object if any of the
provided parameters are invalid.

The meanings of the members are as follows:

=over 4

=item text

The body text of the message.

=item columns

The width to which the message should be justified.  NOTE:  If any line
consisting of the quotification string and the first word is wider than this,
then the line will be generated with that quotification string and that word,
and it will overflow.  Life is hard.

=item output_quotechar

The quotification character to prepend to the text when quoting.  See
C<quotify()>.

=item input_quotechars

The set of characters to be recognized as quotification marks when determining
how to group quoted material.

=item format_params

Miscellaneous parameters to pass for formatting.  See the documentation for the
B<Text::Format> module.

=back

=cut

sub create {
    my ($class, $text, $columns, $output_quotechar, $input_quotechars, $format_params) = @_;

#   check parameters for reasonableness
    return undef if defined $text && !ref($text);
    return undef if defined $columns && ref($columns);
    return undef if defined $output_quotechar && ref($output_quotechar);
    return undef if defined $input_quotechars && ref($input_quotechars);
    return undef if defined $format_params && !ref($format_params);

    return "Quotification character is a multiple-generation quote character!" if ( defined $output_quotechar && defined $input_quotechars && quote_generation($output_quotechar, $input_quotechars) > 1);

#   set up parameter hash
    my $params = {};

    $params->{text} = $text;
    $params->{columns} = $columns;
    $params->{output_quotechar} = $output_quotechar;
    $params->{input_quotechars} = $input_quotechars;
    $params->{format_params} = $format_params;

#   instantiate the object and return it
    my $this = new Mail::QuoteWrap($params);
    return $this;
}

=head1 Private class method

=head2 new

 private class
 (Mail::QuoteWrap) new(hashref params)

Creates a B<Mail::QuoteWrap> object populated by the data in I<params>.

=cut

sub new {
    my ($class, $params) = @_;
    my $this = {};
    bless $this, $class;

    foreach my $param_name (keys %$params) {
	$this->{$param_name} = $params->{$param_name};
    }
    return $this;
}

=head1 Public instance methods

=head2 text

 public instance
 (string []) text()

Returns the text member of the current B<Mail::QuoteWrap> object.

=cut

sub text {
    my ($this) = @_;

    return $this->{text};
}

=head2 set_text

 public instance
 (string) set_text(string[] text)

Sets the text member of the current B<Mail::QuoteWrap> object.  Returns a NULL
string if it succeeds, or a descriptive error message otherwise.

=cut

sub set_text {
    my ($this, $text) = @_;

    return "Supplied text is not an array ref!" unless defined $text && ref($text);
    
    $this->{text} = $text;
    return undef;
}

=head2 columns

 public instance
 (integer) columns()

Returns the columns member of the current B<Mail::QuoteWrap> object.

=cut

sub columns {
    my ($this) = @_;

    return $this->{columns};
}

=head2 set_columns

 public instance
 (string) set_columns(integer columns)

Sets the columns member of the current B<Mail::QuoteWrap> object.  Returns a
NULL string if it succeeds, or a descriptive error message otherwise.

=cut

sub set_columns {
    my ($this, $columns) = @_;

    return "Number of columns is invalid!" unless $columns && !ref($columns);
    $this->{columns} = $columns;
    return undef;
}

=head2 input_quotechars

 public instance
 (string) input_quotechars()

Returns the input_quotechars member of the current B<Mail::QuoteWrap> object.

=cut

sub input_quotechars {
    my ($this) = @_;

    return $this->{input_quotechars};
}

=head2 set_input_quotechars

 public instance
 (string) set_input_quotechars(string input_quotechars)

Sets the input_quotechars member of the current B<Mail::QuoteWrap>
object.  Returns a NULL string if it succeeds, or a descriptive error
message otherwise.

=cut

sub set_input_quotechars {
    my ($this, $input_quotechars) = @_;

    return "Input quote characters are invalid!" unless defined $input_quotechars && !ref($input_quotechars);
    $this->{input_quotechars} = $input_quotechars;
    return undef;
}

=head2 output_quotechar

 public instance
 (string) output_quotechar()

Returns the output_quotechar member of the current B<Mail::QuoteWrap> object.

=cut

sub output_quotechar {
    my ($this) = @_;

    return $this->{output_quotechar};
}

=head2 set_output_quotechar

 public instance
 (string) set_output_quotechar(string output_quotechar)

Sets the output_quotechar member of the current B<Mail::QuoteWrap>
object.  Returns a NULL string if it succeeds, or a descriptive error
message otherwise.

=cut

sub set_output_quotechar {
    my ($this, $output_quotechar) = @_;

    return "Quotification character is invalid!" unless defined $output_quotechar && !ref($output_quotechar);
    return "Quotification character is a multiple-generation quote character!" if ( defined $this->input_quotechars() && quote_generation($output_quotechar, $this->input_quotechars()) > 1);
    $this->{output_quotechar} = $output_quotechar;
    return undef;
}

=head2 format_params

 public instance
 (hashref) format_params()

Returns the format_params member of the current B<Mail::QuoteWrap> object.

=cut

sub format_params {
    my ($this) = @_;

    return $this->{format_params};
}

=head2 set_format_params

 public instance
 (string) set_format_params(hashref format_params)

Sets the format_params member of the current B<Mail::QuoteWrap>
object.  Returns a NULL string if it succeeds, or a descriptive error
message otherwise.

=cut

sub set_format_params {
    my ($this, $format_params) = @_;

    return "Supplied format_params is not a hashref!" unless defined $format_params && ref($format_params);
    $this->{format_params} = $format_params;
    return undef;
}

=head2 quotify

 public instance
 (string) quotify()

Quotifies all current text with the string in C<output_quotechar()>.
Modifies the I<input_quotechars> member to reflect that the text is now
quotified.  Returns a NULL string if it succeeds, or a descriptive error
message otherwise.

=cut

sub quotify {
    my ($this) = @_;

    # Load members of the current object for slightly faster reference
    my $input_quotechars = $this->input_quotechars();
    my $output_quotechar = $this->output_quotechar();
    my $text = $this->text();

    # Check that the necessary members are valid.  We do not care about
    # format_text or columns at this time.
    return "Supplied text is not valid!" unless defined($text) && ref($text);
    return "Supplied input_quotechars is not valid!" unless defined($input_quotechars) && !ref($input_quotechars);
    return "Supplied output_quotechar is not valid!" unless defined($output_quotechar) && !ref($output_quotechar);

#   construct the quoted text
    my @new_text = ();
    foreach my $line (@$text) {
	my $new_line = $output_quotechar.$line;
	push @new_text, $new_line;
    }

#   add output_quotechar to the input_quotechars member; we do this in
#   case output_quotechar is not included in input_quotechars, so that the
#   text can be recognized as quoted material.

    $this->{input_quotechars} .= $output_quotechar;
#   put the quoted text into the object
    return $this->set_text(\@new_text);
}

=head2 format

 public instance
 (string) format()

This method alters the I<text> member of the current
B<Mail::QuoteWrap> object to conform to the constraints implied in the
I<columns> and I<format_params> members.  It recognizes the
quotification characters in I<input_quotechars> and uses them to lump
related quoted material together.  C<format()> will use the same
quotification character at the beginning of each line within a block
of quoted material which it believes to be related.  Returns a NULL
string if it succeeds, or a descriptive error message otherwise.

=cut

sub format {
    my ($this) = @_;

    # Load members of the current object for slightly faster reference
    my $text = $this->text();
    my $columns = $this->columns();
    my $input_quotechars = $this->input_quotechars();
    my $format_params = $this->{format_params};

    # Check that the necessary members are valid.  We care about all of the
    # members at this time except for output_quotechar.
    return "Supplied text is invalid!" unless defined($text) && ref($text);
    return "Supplied input_quotechars is invalid!" unless defined($input_quotechars) && !ref($input_quotechars);
    return "Supplied columns is invalid!" unless $columns && !ref($columns);
    return "Supplied format_params is invalid!" unless defined($format_params) && ref($format_params);

#   break the text into blocks of same-generation quoted material    
    my $broken_into_blocks = break_text_into_blocks($text, $input_quotechars);

    my @new_text = ();

#   set up each block to be converted into paragraphs, justified and
#   formatted

    foreach my $block (@$broken_into_blocks) {
	my $message_block = [];
	foreach my $message_line (@{$block->{message}}) {
	   push @$message_block, $message_line;
	}

#       calculate column width for the message text, defaulting to 1 in the
#       case that the quotification characters are wider than the specified
#       justification.  Text::Format will deal.
        my $width = $this->columns() - length($block->{quotification});
        $format_params->{columns} = ($width > 0) ? $width : 1;

#       default to not indenting the first line of every paragraph
        $format_params->{firstIndent} = 0 unless exists $format_params->{firstIndent};

#       construct the new, formatted block
        my @new_message_block = ();

#       must special-case for a message block with only whitespace text
#       since Text::Format tends to mess these over
        if ( (join ' ', @$message_block) =~ /^[\t ]$/ ) {
	    push @new_message_block, " ";
	}
	else {
	    my ($paragraphs) = break_block_into_paragraphs($message_block);
            my $formatted_message_block = new Text::Format($format_params);
	    foreach my $paragraph (@$paragraphs) {
		push @new_message_block, $formatted_message_block->format($paragraph);
	    }
	}

#       construct the output, removing newlines from the end of each line
        foreach my $message_line (@new_message_block) {
	    my $line = $block->{quotification}.$message_line;
            chomp $line;
	    push @new_text, $line;
	}

    }
    
    return $this->set_text(\@new_text);
}

=head1 Private utility methods

=head2 parse_quotification

 private
 (string, string) parse_quotification (string text, string quotechars)

Returns two strings:  the quotification part of the line of text (consisting
of all characters at the beginning of the line which are tabs, spaces, or
characters in I<quotechars>), and the remainder of the line.  Returns two NULL
strings if this matching does not work out.

=cut

sub parse_quotification {
    my ($text, $quotechars) = @_;

    return (undef, undef) unless (my ($quotification, $message) = ($text =~ /^([$quotechars \t]*)(.*)$/));
    ($quotification, my $whitespace) = ( $quotification =~ /^([$quotechars \t]*?)([ \t]*)$/);
    $message = $whitespace . $message;
    $message = " " unless length $message;
    return ($quotification, $message);

}
    
=head2 quote_generation

 private
 (integer) quote_generation(string quotification, string quotechars)

Given the quotification portion of a line of text and the accepted quote
characters, returns the presumed generation of the quote (zeroth -- original
text, first -- once-quoted text, etc.)

=cut

sub quote_generation {
    my ($quotification, $quotechars) = @_;

    $quotification =~ tr/[^$quotechars]//;
    return length $quotification;
}

=head2 break_text_into_blocks

 private
 (hashref []) break_text_into_blocks (string[] text, string quotechars)

Breaks I<text> into a list of elements, each of which is a hash with the
following elements:

=over 4

=item quotification

Quotification string to use for this block.

=item message

Array ref containing the message text; undef if the message portion is blank.

=back      

Each message element is guaranteed to consist of lines of same-generation
quotage -- i.e., a block will contain only first-generation quotes,
second-generation, zeroth-generation, or what have you.  Each line with blank
message text gets its own block, to preserve vertical whitespace.

=cut

sub break_text_into_blocks {
    my ($text, $quotechars) = @_;

#   set up holding areas for the output list and the current block of text

    my $outlist = [];
    my $current_block = {};

#   put the first line into current_block

    my $line = shift @$text;
    my ($quotification, $message) = parse_quotification($line, $quotechars);
    my $current_generation = quote_generation($quotification, $quotechars);
    push @{$current_block->{message}}, $message;
    $current_block->{quotification} = $quotification;

#   if it's a blank line, push onto outlist and clear current_block

    if ($message =~ /^\s*$/) {
	copy_and_push($current_block, $outlist);
	$current_block = {};
    }

    foreach $line (@$text) {
        ($quotification, $message) = parse_quotification($line, $quotechars);
	my $generation = quote_generation($quotification, $quotechars);

#       if it's the start of a new block, push the previous contents onto
#       @$outlist, clear $current_block, and set
#       $current_block->{quotification}
	
	if (($message =~ /^\s*$/) || ($generation != $current_generation)) {
	    copy_and_push($current_block, $outlist);
	    $current_block = {};
            $current_block->{quotification} = $quotification;
            $current_generation = $generation;
	}

        push @{$current_block->{message}}, $message;

#       if the current line is blank, push it onto @$outlist as well
#       and flag $current_generation to force the next line to be its own block

        if ($message =~ /^\s*$/) {
	    copy_and_push($current_block, $outlist);
            $current_block = {};
	    undef $current_generation;
	}

    }
    
    copy_and_push($current_block, $outlist) if scalar(@{$current_block->{message}});

    return $outlist;

}

=head2 copy_and_push

 private
 (string) copy_and_push(hashref current_block, arrayref outlist)

Pushes a copy of the contents of I<current_block> onto I<outlist>.
I<current_block> is assumed to have two members as described in the
documentation for C<break_text_into_blocks()> above.  Returns a NULL
string if it succeeds, or a descriptive error message otherwise.

=cut

sub copy_and_push {
    my ($current_block, $outlist) = @_;

    return "Current block passed is invalid!" unless defined $current_block && ref($current_block);
    return "Output list passed is invalid!" unless defined $outlist && ref($outlist);

    return undef unless ref($current_block->{message}) && scalar(@{$current_block->{message}});
    my $copy_current_block = {};

    $copy_current_block->{quotification} = $current_block->{quotification};
    $copy_current_block->{message} = [];

    foreach my $line (@{$current_block->{message}}) {
	push @{$copy_current_block->{message}}, $line;
    }

    push @$outlist, $copy_current_block;

    return undef;
}

=head2 break_block_into_paragraphs

 private
 (string[]) break_block_into_paragraphs(string[] block)

Breaks the block into paragraphs according to the following rule:

If the previous line ended with a period and the current line begins with a tab
or at least three spaces, the current line begins a new paragraph.

=cut

sub break_block_into_paragraphs {
    my ($block) = @_;

    my $prev_line = undef;
    my $current_paragraph = [];
    my $outlist = [];

    foreach my $line (@$block) {
	if ( ($prev_line =~ /\.$/) && ( ($line =~ /^  /) || ($line =~ /^\t/) ) ) {
	    my $copy_para = [];
	    foreach my $line_in_para (@$current_paragraph) {
		push @$copy_para, $line_in_para;
	    }
	    push @$outlist, $copy_para;
	    $current_paragraph = [];
	}

	push @$current_paragraph, $line;
        $prev_line = $line;
    }

    push @$outlist, $current_paragraph if scalar(@$current_paragraph);
    return $outlist;
}

1;
