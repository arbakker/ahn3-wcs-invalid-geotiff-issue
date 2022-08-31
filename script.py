import re
import os
import argparse


def split_multipart(input_file, output_dir="./"):
    with open(input_file, mode="rb") as tf:
        count = 0
        t_byte = tf.read(1)
        string_buffer = ""
        file_name = ""
        start_collecting_bytes = False
        start_bytes = -1
        end_bytes = -1

        while t_byte:
            try:
                text = t_byte.decode("utf-8")
                string_buffer += text
                regexp = re.compile(
                    r".*\r\n.*-.*:.*?\r\n\r\n", re.MULTILINE
                )  # match last response-header in section
                if start_collecting_bytes:
                    if string_buffer.endswith("--wcs"):

                        end_bytes = count - 5
                        start_collecting_bytes = False
                        file_name = os.path.join(output_dir, file_name)
                        dirname = os.path.dirname(file_name)
                        try:
                            os.mkdir(dirname)
                        except OSError as error:
                            pass
                        with open(input_file, mode="rb") as bf, open(
                            file_name, "wb"
                        ) as of:  # open for [w]riting as [b]inary
                            bf.seek(start_bytes)
                            data = bf.read(end_bytes - start_bytes)
                            of.write(data)
                            print(f"written {file_name}")
                            string_buffer = "--wcs"
                elif "--wcs" in string_buffer and regexp.search(string_buffer):
                    # print(string_buffer)
                    start_collecting_bytes = True
                    regexp = re.compile(r".*Content-ID:\s(.*?)\n", re.MULTILINE)
                    result = regexp.search(string_buffer)
                    file_name = result.group(1)
                    file_name = file_name.replace("\r", "")
                    start_bytes = count + 1
            except UnicodeDecodeError as e:
                string_buffer = ""
                pass
            except ValueError as ve:
                string_buffer = ""
                pass
            finally:
                t_byte = tf.read(1)
                count += 1


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("input_file")
    parser.add_argument("-o", "--output-dir", default="./")
    args = parser.parse_args()
    input_file = args.input_file
    output_dir = args.output_dir
    split_multipart(input_file, output_dir)
