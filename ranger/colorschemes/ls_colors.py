from ranger.gui.colorscheme import ColorScheme
import ranger.gui.color as style
import ranger.gui.context
import ranger.gui.widgets.browsercolumn
from os import getenv
from subprocess import check_output, CalledProcessError
from ranger.gui.color import (
    black, blue, cyan, green, magenta, red, white, yellow, default,
    normal, bold, reverse, dim, BRIGHT,
    default_colors,
)


class ls_colors(ColorScheme):
    def __init__(self):
        super(ColorScheme, self).__init__()
        try:
            self.ls_colors = getenv('LS_COLORS',
                                    self.get_default_lscolors()).split(':')
        except (CalledProcessError, FileNotFoundError):
            self.ls_colors = []

        # Gets all the keys corresponding to extensions
        self.ls_colors_extensions = [
            k.split('=')[0] for k in self.ls_colors if k != ''
        ]
        self.ls_colors_extensions = [
            '.' + k.split('*.')[1] for k in self.ls_colors_extensions
            if '*.' in k
        ]

        # Add the key names to ranger context keys
        for key in self.ls_colors_extensions:
            ranger.gui.context.CONTEXT_KEYS.append(key)
            setattr(ranger.gui.context.Context, key, False)

        self.OLD_HOOK_BEFORE_DRAWING = ranger.gui.widgets.browsercolumn.hook_before_drawing

        ranger.gui.widgets.browsercolumn.hook_before_drawing = self.new_hook_before_drawing

        self.ls_colors_keys = [k.split('=') for k in self.ls_colors if k != '']
        self.tup_ls_colors = []

        # Not considering file extensions
        # The order of these two block matters, as extensions colouring should
        # take precedence over the 'file' type
        for key in [k for k in self.ls_colors_keys if '.*' not in k]:
            if key[0] == 'fi':
                self.tup_ls_colors += [('file', key[1])]

        # Considering files extensions
        self.tup_ls_colors += [('.' + k[0].split('*.')[1], k[1])
                               for k in self.ls_colors_keys if '*.' in k[0]]

        # This is added last because their color should take precedence over
        # what's been set before for a 'file' that would have the same
        # extension
        for key in [k for k in self.ls_colors_keys if '.*' not in k]:
            if key[0] == 'ex':
                self.tup_ls_colors += [('executable', key[1])]
            elif key[0] == 'pi':
                self.tup_ls_colors += [('fifo', key[1])]
            elif key[0] == 'ln':
                self.tup_ls_colors += [('link', key[1])]
            elif key[0] == 'bd' or key[0] == 'cd':
                self.tup_ls_colors += [('device', key[1])]
            elif key[0] == 'so':
                self.tup_ls_colors += [('socket', key[1])]
            elif key[0] == 'di':
                self.tup_ls_colors += [('directory', key[1])]

        # Those special context shouldn't get attributes destined to
        # files, based on extension
        self.__special_context = [
            "directory",
            "fifo",
            "link",
            "device",
            "socket"
        ]

        self.progress_bar_color = 1

    def new_hook_before_drawing(self, fsobject, color_list):
        for key in self.ls_colors_extensions:
            if fsobject.basename.endswith(key):
                color_list.append(key)

        return self.OLD_HOOK_BEFORE_DRAWING(fsobject, color_list)

    def get_default_lscolors(self):
        """Returns the default value for LS_COLORS
        as parsed from the `dircolors` command
        """
        ls_colors = check_output('dircolors')
        ls_colors = ls_colors.splitlines()[0].decode('UTF-8').split("'")[1]
        return ls_colors

    def get_attr_from_lscolors(self, attribute_list):
        return_attr = 0
        to_delete = []

        for i, attr in enumerate(attribute_list):
            if attr == 1:
                return_attr |= style.bold
            elif attr == 4:
                return_attr |= style.underline
            elif attr == 5:
                return_attr |= style.blink
            elif attr == 7:
                return_attr |= style.reverse
            elif attr == 8:
                return_attr |= style.invisible
            to_delete.append(i)

        # remove style attrattributes  from the array
        attribute_list[:] = [val for i, val in enumerate(attribute_list) if i in to_delete]

        return return_attr

    def make_colour_bright(self, colour_value):
        """Only applicable to not already bright 8 bit colours.
        256 colour will be returned "as-is"
        """

        if colour_value < 8 and colour_value >= 0:
            colour_value += style.BRIGHT
        return colour_value

    # Values from
    # https://en.wikipedia.org/wiki/ANSI_escape_code#Colors
    def get_colour_from_attributes(self, attribute_list):
        """Get the colour from the different attributes passed
        """
        fg_colour = None
        bg_colour = None
        looking_at_256_ttl = 0
        for i, current_attr in enumerate(attribute_list):
            #################
            #  256 colours  #
            #################

            if looking_at_256_ttl > 0:
                looking_at_256_ttl -= 1
                continue
            # If colour256, we need to get to the third field (after 48 and 5)
            # to get the colour
            try:
                if current_attr == 48 and attribute_list[i + 1] == 5:
                    bg_colour = attribute_list[i + 2]
                    looking_at_256_ttl = 2
                elif current_attr == 38 and attribute_list[i + 1] == 5:
                    fg_colour = attribute_list[i + 2]
                    looking_at_256_ttl = 2
            except IndexError:
                print('Bad attribute value for LS_COLORS: {}'.format(attribute_list))
                exit(1)

            ######################
            #  Standard colours  #
            ######################

            # Standard colours
            if (current_attr >= 30 and current_attr <= 37):
                fg_colour = current_attr - 30
            # Bright
            elif (current_attr >= 90 and current_attr <= 97):
                fg_colour = current_attr - 82

            # Standard colours
            elif (current_attr >= 40 and current_attr <= 47):
                bg_colour = current_attr - 40
            # Bright
            elif (current_attr >= 100 and current_attr <= 107):
                bg_colour = current_attr - 92

        return fg_colour, bg_colour

    def is_special_file_context(self, context):
        """Return True if we are in a special file context
        """

        for special_key in self.__special_context:
            if getattr(context, special_key):
                return True
        return False

    def use(self, context):
        fg, bg, attr = style.default_colors

        for key, t_attributes in self.tup_ls_colors:
            if getattr(context, key):
                # This means we're most likely applying extension colouring to
                # a special file (e.g. directory, link, etc.)
                if self.is_special_file_context(context) and key not in self.__special_context:
                    continue

                t_attributes = t_attributes.split(';')
                try:
                    t_attributes[:] = [int(attrib) for attrib in t_attributes]
                except ValueError:
                    print("Bad attribute value for LS_COLORS: {}".format(attr))
                    exit(1)

                new_attr = self.get_attr_from_lscolors(t_attributes)
                if new_attr is not None:
                    attr |= new_attr
                fg_colour, bg_colour = self.get_colour_from_attributes(t_attributes)

                if fg_colour is not None:
                    fg = fg_colour
                if bg_colour is not None:
                    bg = bg_colour

        if context.reset:
            return style.default_colors
        elif context.in_browser:
            if context.selected:
                attr |= style.reverse
            if context.tag_marker and not context.selected:
                attr |= style.bold
                if fg in (style.red, style.magenta):
                    fg = style.white
                else:
                    fg = style.red
                fg = self.make_colour_bright(fg)
            if not context.selected and (context.cut or context.copied):
                attr |= style.bold
                fg = style.black
                fg = self.make_colour_bright(fg)
                # If the terminal doesn't support bright colors, use
                # dim white instead of black.
                if style.BRIGHT == 0:
                    attr |= style.dim
                    fg = style.white
            if context.main_column:
                # Doubling up with BRIGHT here causes issues because
                # it's additive not idempotent.
                if context.selected:
                    attr |= style.bold
                if context.marked:
                    attr |= style.bold
                    fg = style.yellow
        elif context.in_titlebar:
            if context.hostname:
                fg = red if context.bad else green
            attr |= bold


        return fg, bg, attr
