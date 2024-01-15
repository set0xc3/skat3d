package core

import "core:math/rand"
import "core:strings"

UUID_SIZE :: 16
UUID4 :: []byte

uuid4_generate :: proc() -> UUID4 #no_bounds_check {
	r: rand.Rand
	rand.init_as_system(&r)

	u := make(UUID4, UUID_SIZE)
	n := rand.read(u, &r)
	assert(n == UUID_SIZE)

	u[6] = (u[6] & 0x0f) | (4 << 4)
	u[8] = (u[8] & (0xff >> 2) | (0x02 << 6))
	return u
}

uuid4_string :: proc(u: UUID4) -> string #no_bounds_check {
	buf := make([]byte, 36)

	hex(buf[0:8], u[0:4])
	buf[8] = '-'
	hex(buf[9:13], u[4:6])
	buf[13] = '-'
	hex(buf[14:18], u[6:8])
	buf[18] = '-'
	hex(buf[19:23], u[8:10])
	buf[23] = '-'
	hex(buf[24:], u[10:])

	return string(buf)
}

HEXTABLE := [16]byte {
	'0',
	'1',
	'2',
	'3',
	'4',
	'5',
	'6',
	'7',
	'8',
	'9',
	'a',
	'b',
	'c',
	'd',
	'e',
	'f',
}

hex :: proc(dst, src: []byte) #no_bounds_check {
	i := 0
	for v in src {
		dst[i] = HEXTABLE[v >> 4]
		dst[i + 1] = HEXTABLE[v & 0x0f]
		i += 2
	}
}
