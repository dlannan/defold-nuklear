# defold-nuklear

An extension for Defold to provide Nuklear immediate mode gui capabilities. 
General reasoning for this extension development:
- Needed gui with drawing
- Needed to be able to build gui targets for web asm
- Wanted to have a simple "one header" style solution (ended up with a few files).

Example screenshots:

![alt text](https://github.com/dlannan/defold-nuklear/blob/main/screenshots/2024-03-21_22-02.png?raw=true)

![alt text](https://github.com/dlannan/defold-nuklear/blob/main/screenshots/2024-03-21_22-02_1.png?raw=true)
The above was developed for an ISS Live viewer here:
https://bukkat.itch.io/isslive

## Examples

Current use in an application Im developing called Flix.

![alt text](https://github.com/dlannan/defold-nuklear/blob/main/screenshots/2024-06-19_00-23.png?raw=true)


## Notes

The extension is based on the original Nuklear repo here:
https://github.com/vurtun/nuklear

The aim is to expand the api and make the majority of the Nuklear api available via defold. Some of the todo items are:
- Add middle and right mouse button input events
- Add middle mouse button scroll wheel
- Add more Nuklear commands
- Add image specific commands
- Append some new styles
